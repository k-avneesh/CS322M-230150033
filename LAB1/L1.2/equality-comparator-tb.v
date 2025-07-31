`timescale 1ns / 1ns
module equality4bit_tb;

  reg [3:0] a, b;
  wire eq;

  equality4bit uut (
    .A(a),
    .B(b),
    .eq(eq)
  );

  initial begin
    $dumpfile("equality4bit_waveform.vcd");
    $dumpvars(0, equality4bit_tb);

    a = 4'b0000; b = 4'b0000; 
    #10;
    a = 4'b0010; b = 4'b0010; 
    #10;
    a = 4'b1001; b = 4'b0000; 
    #10;
    a = 4'b0001; b = 4'b1000; 
    #10;
    a = 4'b1111; b = 4'b1111; 
    #10;

    $finish;
  end

endmodule