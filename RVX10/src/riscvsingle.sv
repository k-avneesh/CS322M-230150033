// riscvsingle.sv

// RISC-V single-cycle processor
// From Section 7.6 of Digital Design & Computer Architecture
// 27 April 2020
// David_Harris@hmc.edu 
// Sarah.Harris@unlv.edu

// run 210
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)

// Single-cycle implementation of RISC-V (RV32I)
// User-level Instruction Set Architecture V2.2 (May 7, 2017)
// Implements a subset of the base integer instructions:
//    lw, sw
//    add, sub, and, or, slt, 
//    addi, andi, ori, slti
//    beq
//    jal
// Exceptions, traps, and interrupts not implemented
// little-endian memory

// 31 32-bit registers x1-x31, x0 hardwired to 0
// R-Type instructions
//   add, sub, and, or, slt
//   INSTR rd, rs1, rs2
//   Instr[31:25] = funct7 (funct7b5 & opb5 = 1 for sub, 0 for others)
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// I-Type Instructions
//   lw, I-type ALU (addi, andi, ori, slti)
//   lw:         INSTR rd, imm(rs1)
//   I-type ALU: INSTR rd, rs1, imm (12-bit signed)
//   Instr[31:20] = imm[11:0]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// S-Type Instruction
//   sw rs2, imm(rs1) (store rs2 into address specified by rs1 + immm)
//   Instr[31:25] = imm[11:5] (offset[11:5])
//   Instr[24:20] = rs2 (src)
//   Instr[19:15] = rs1 (base)
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:0]  (offset[4:0])
//   Instr[6:0]   = opcode
// B-Type Instruction
//   beq rs1, rs2, imm (PCTarget = PC + (signed imm x 2))
//   Instr[31:25] = imm[12], imm[10:5]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:1], imm[11]
//   Instr[6:0]   = opcode
// J-Type Instruction
//   jal rd, imm  (signed imm is multiplied by 2 and added to PC, rd = PC+4)
//   Instr[31:12] = imm[20], imm[10:1], imm[11], imm[19:12]
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode

//   Instruction  opcode    funct3    funct7
//   add          0110011   000       0000000
//   sub          0110011   000       0100000
//   and          0110011   111       0000000
//   or           0110011   110       0000000
//   slt          0110011   010       0000000
//   addi         0010011   000       immediate
//   andi         0010011   111       immediate
//   ori          0010011   110       immediate
//   slti         0010011   010       immediate
//   beq          1100011   000       immediate
//   lw	          0000011   010       immediate
//   sw           0100011   010       immediate
//   jal          1101111   immediate immediate

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);

  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if((DataAdr === 100) && (WriteData === 25)) begin
          $display("Simulation succeeded");
          $display("CHECKSUM (x28) = %0d (0x%08h)", dut.rvsingle.dp.rf.rf[28], dut.rvsingle.dp.rf.rf[28]);
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end


  // Debugging Purposes to see result of RVX10 operations
  wire        wb_we   = dut.rvsingle.dp.RegWrite;
  wire [31:0] wb_val  = dut.rvsingle.dp.Result;        // data written to rd
  wire  [4:0] wb_rd   = dut.rvsingle.dp.Instr[11:7];   // rd field

  wire [6:0] opcode = dut.rvsingle.dp.Instr[6:0];

  always @(negedge clk) begin
    if (wb_we && (wb_rd != 5'd0) && (opcode == 7'b0001011)) begin
      $display("VALUE AFTER OPERATION IS %0d (0x%08h) [RVX10] -> x%0d  t=%0t",
                wb_val, wb_val, wb_rd, $time);
    end
  end
endmodule

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, 
                       WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, reset,MemWrite, DataAdr, WriteData, ReadData);
endmodule

module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PC,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  logic       ALUSrc, RegWrite, Jump, Zero;
  logic [1:0] ResultSrc, ImmSrc;
  logic [4:0] ALUControl;

  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump,
               ImmSrc, ALUControl);
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl,
              Zero, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule

module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] Instr_funct7,
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       PCSrc, ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic [1:0] ImmSrc,
                  output logic [4:0] ALUControl);

  logic [1:0] ALUOp;
  logic       Branch;

  maindec md(op, ResultSrc, MemWrite, Branch,
             ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);
  aludec  ad(op, funct3, Instr_funct7, ALUOp, ALUControl);

  assign PCSrc = Branch & Zero | Jump;
endmodule

module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp);

  logic [10:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type 
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      7'b0001011: controls = 11'b1_xx_0_0_00_0_10_0; // RVX10 (CUSTOM-0)
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

module aludec(input  logic [6:0] op,
              input  logic [2:0] funct3,
              input  logic [6:0] funct7, 
              input  logic [1:0] ALUOp,
              output logic [4:0] ALUControl);

  // ALUControl encodings (keep legacy codes compatible in LSBs)
  localparam [4:0] ALU_ADD  = 5'b00000;
  localparam [4:0] ALU_SUB  = 5'b00001;
  localparam [4:0] ALU_AND  = 5'b00010;
  localparam [4:0] ALU_OR   = 5'b00011;
  localparam [4:0] ALU_XOR  = 5'b00100;
  localparam [4:0] ALU_SLT  = 5'b00101;
  localparam [4:0] ALU_SLL  = 5'b00110;
  localparam [4:0] ALU_SRL  = 5'b00111;
  // RVX10
  localparam [4:0] ALU_ANDN = 5'b01000;
  localparam [4:0] ALU_ORN  = 5'b01001;
  localparam [4:0] ALU_XNOR = 5'b01010;
  localparam [4:0] ALU_MIN  = 5'b01011;
  localparam [4:0] ALU_MAX  = 5'b01100;
  localparam [4:0] ALU_MINU = 5'b01101;
  localparam [4:0] ALU_MAXU = 5'b01110;
  localparam [4:0] ALU_ROL  = 5'b01111;
  localparam [4:0] ALU_ROR  = 5'b10000;
  localparam [4:0] ALU_ABS  = 5'b10001;

  logic  RtypeSub;
  assign RtypeSub = funct7[5] & op[5];  // TRUE for R-type subtract instruction

  always_comb begin
    // Default
    ALUControl = ALU_ADD;
    if (op == 7'b0001011) begin
      // CUSTOM-0 => RVX10
      case ({funct7,funct3})
        {7'b0000000,3'b000}: ALUControl = ALU_ANDN;
        {7'b0000000,3'b001}: ALUControl = ALU_ORN;
        {7'b0000000,3'b010}: ALUControl = ALU_XNOR;
        {7'b0000001,3'b000}: ALUControl = ALU_MIN;
        {7'b0000001,3'b001}: ALUControl = ALU_MAX;
        {7'b0000001,3'b010}: ALUControl = ALU_MINU;
        {7'b0000001,3'b011}: ALUControl = ALU_MAXU;
        {7'b0000010,3'b000}: ALUControl = ALU_ROL;
        {7'b0000010,3'b001}: ALUControl = ALU_ROR;
        {7'b0000011,3'b000}: ALUControl = ALU_ABS;
        default:             ALUControl = ALU_ADD; // safe default
      endcase
    end else begin
      // Base RV32I behavior (as original)
      case(ALUOp)
        2'b00:                ALUControl = ALU_ADD; // addition
        2'b01:                ALUControl = ALU_SUB; // subtraction
        default: case(funct3) // R-type or I-type ALU
                   3'b000:  if (RtypeSub) 
                              ALUControl = ALU_SUB; // sub
                            else          
                              ALUControl = ALU_ADD; // add, addi
                   3'b010:    ALUControl = ALU_SLT; // slt, slti
                   3'b110:    ALUControl = ALU_OR;  // or, ori
                   3'b111:    ALUControl = ALU_AND; // and, andi
                   default:   ALUControl = ALU_ADD; // default
                 endcase
      endcase
    end
  end
endmodule

module datapath(input  logic        clk, reset,
                input  logic [1:0]  ResultSrc, 
                input  logic        PCSrc, ALUSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [4:0]  ALUControl,
                output logic        Zero,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData);

  logic [31:0] PCNext, PCPlus4, PCTarget;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;

  // next PC logic
  flopr #(32) pcreg(clk, reset, PCNext, PC); 
  adder       pcadd4(PC, 32'd4, PCPlus4);
  adder       pcaddbranch(PC, ImmExt, PCTarget);
  mux2 #(32)  pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, WriteData);
  extend      ext(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux2 #(32)  srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule

module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [ 4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3 && (a3 != 5'd0)) rf[a3] <= wd3;
    // fix 0 writes
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

module adder(input  [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule

module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);
 
  logic [31:0] imm_i, imm_s, imm_b, imm_j;

  assign imm_i = {{20{instr[31]}}, instr[31:20]};
  assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  assign imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_j = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  always_comb
    case (immsrc)
      2'b00:   immext = imm_i;
      2'b01:   immext = imm_s;
      2'b10:   immext = imm_b;
      2'b11:   immext = imm_j;
      default: immext = 32'bx;
    endcase
         
endmodule

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[0:63];

  initial 
    $readmemh("tests/rvx10.hex", RAM);


  assign rd = RAM[a >> 2]; // word aligned
endmodule

module dmem(input  logic        clk, 
            input logic reset , we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[0:63];

  assign rd = RAM[a >> 2]; // word aligned

  always_ff @(posedge clk)
    if (we && !reset) RAM[a >> 2] <= wd;
endmodule

module alu(input  logic [31:0] a, b,
           input  logic [4:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  // Legacy add/sub wiring reused
  logic [31:0] condinvb, sum;
  logic        v;              // overflow for add/sub
  logic        isAddSub;       // true when is add or subtract operation

  // Control encodings (must match aludec)
  localparam [4:0] ALU_ADD  = 5'b00000;
  localparam [4:0] ALU_SUB  = 5'b00001;
  localparam [4:0] ALU_AND  = 5'b00010;
  localparam [4:0] ALU_OR   = 5'b00011;
  localparam [4:0] ALU_XOR  = 5'b00100;
  localparam [4:0] ALU_SLT  = 5'b00101;
  localparam [4:0] ALU_SLL  = 5'b00110;
  localparam [4:0] ALU_SRL  = 5'b00111;
  // RVX10
  localparam [4:0] ALU_ANDN = 5'b01000;
  localparam [4:0] ALU_ORN  = 5'b01001;
  localparam [4:0] ALU_XNOR = 5'b01010;
  localparam [4:0] ALU_MIN  = 5'b01011;
  localparam [4:0] ALU_MAX  = 5'b01100;
  localparam [4:0] ALU_MINU = 5'b01101;
  localparam [4:0] ALU_MAXU = 5'b01110;
  localparam [4:0] ALU_ROL  = 5'b01111;
  localparam [4:0] ALU_ROR  = 5'b10000;
  localparam [4:0] ALU_ABS  = 5'b10001;

  // signed views
  wire signed [31:0] s1 = a;
  wire signed [31:0] s2 = b;
  logic [31:0] add_res, sub_res;
  assign add_res = a + b;
  assign sub_res = a - b;

  always_comb begin
    case (alucontrol)
      ALU_ADD : result = add_res;
      ALU_SUB : result = sub_res;
      ALU_AND : result = a & b;
      ALU_OR  : result = a | b;
      ALU_XOR : result = a ^ b;
      ALU_SLT : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLL : result = a << b[4:0];
      ALU_SRL : result = a >> b[4:0];
      ALU_ANDN: result = a & ~b;
      ALU_ORN : result = a | ~b;
      ALU_XNOR: result = ~(a ^ b);
      ALU_MIN : result = ($signed(a) < $signed(b)) ? a : b;
      ALU_MAX : result = ($signed(a) > $signed(b)) ? a : b;
      ALU_MINU: result = (a < b) ? a : b;
      ALU_MAXU: result = (a > b) ? a : b;
      ALU_ROL: begin
        logic [4:0] sh, nsh;
        sh  = b[4:0];
        nsh = (5'd31 - sh) + 5'd1;   // = (32 - sh) % 32
        result = (sh == 5'd0) ? a : ((a << sh) | (a >> nsh));
      end
      ALU_ROR: begin
        logic [4:0] sh, nsh;
        sh  = b[4:0];
        nsh = (5'd31 - sh) + 5'd1;   // = (32 - sh) % 32
        result = (sh == 5'd0) ? a : ((a >> sh) | (a << nsh));
      end
      ALU_ABS : result = ($signed(a) >= 0) ? a : (32'b0 - a);
      default : result = 32'b0;
    endcase
  end

assign zero = (result == 32'b0);

endmodule
