`timescale 1ns/1ps
module tb_seq_detect_mealy;
    reg clk = 0, rst = 1, din = 0;
    wire y;
    reg [10:0] stream;   // <-- move here (module scope)

    seq_detect_mealy dut(.clk(clk), .rst(rst), .din(din), .y(y));

    always #5 clk = ~clk;

    task send(input b);  // 1-bit input
        begin
            @(negedge clk);
            din = b;
            @(posedge clk);
        end
    endtask

    integer i, detects;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_seq_detect_mealy);

        repeat (3) @(posedge clk);
        rst = 1'b0;

        // Stream bits
        stream[0]=1; stream[1]=1; stream[2]=0; stream[3]=1;
        stream[4]=1; stream[5]=0; stream[6]=1;
        stream[7]=1; stream[8]=1; stream[9]=0; stream[10]=1;

        detects = 0;
        for (i=0; i<=10; i=i+1) begin
            send(stream[i]);
            if (y) begin
                $display("%0t ns: DETECT at index %0d", $time, i);
                detects = detects + 1;
            end
        end

        // Verilog random
        repeat (10) begin
            send($random & 1);
            if (y) begin
                $display("%0t ns: DETECT (random)", $time);
                detects = detects + 1;
            end
        end

        $display("Total detects: %0d", detects);
        #20 $finish;
    end
endmodule
