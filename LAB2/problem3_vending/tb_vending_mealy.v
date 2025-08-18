`timescale 1ns/1ps
module tb_vending_mealy;
reg clk = 0, rst = 1;
reg [1:0] coin = 2'b00;
wire dispense, chg5;

vending_mealy dut(.clk(clk), .rst(rst), .coin(coin), .dispense(dispense), .chg5(chg5));

always #5 clk = ~clk; // 100 MHz

task put5; begin
    @(negedge clk); coin = 2'b01;
    @(posedge clk); // sampled
    @(negedge clk); coin = 2'b00;
end endtask

task put10; begin
    @(negedge clk); coin = 2'b10;
    @(posedge clk);
    @(negedge clk); coin = 2'b00;
end endtask

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_vending_mealy);
    repeat (3) @(posedge clk);
    rst = 1'b0;

    // 10+10 => vend
    put10(); if (dispense) $display("Unexpected vend early");
    put10(); @(posedge clk);
    if (dispense && !chg5) $display("%0t ns: VEND (20)", $time);

    // 5+5+10 => vend
    put5(); put5(); put10(); @(posedge clk);
    if (dispense && !chg5) $display("%0t ns: VEND (20)", $time);

    // 10+5+10 => vend + chg5
    put10(); put5(); put10(); @(posedge clk);
    if (dispense && chg5) $display("%0t ns: VEND (25) + CHANGE 5", $time);

    // Idle robustness
    @(negedge clk); coin = 2'b11; @(posedge clk); @(negedge clk); coin = 2'b00;

    #50 $finish;
end

endmodule