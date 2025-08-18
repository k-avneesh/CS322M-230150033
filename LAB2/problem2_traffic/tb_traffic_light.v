// CS322M Problem 2 TB: Traffic light with testbench-generated tick
`timescale 1ns/1ps
module tb_traffic_light;
reg clk = 0, rst = 1, tick = 0;
wire ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;
traffic_light dut(
    .clk(clk), .rst(rst), .tick(tick),
    .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
    .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
);

// 100 MHz
always #5 clk = ~clk;

integer cyc = 0;
// Fast simulation tick: 1-cycle pulse every 10 clock cycles
always @(posedge clk) begin
    cyc <= cyc + 1;
    tick <= (cyc % 10 == 0);
    if (tick) begin
        $display("%0t ns TICK | NS[gyr]=%0d%0d%0d EW[gyr]=%0d%0d%0d",
                 $time, ns_g,ns_y,ns_r, ew_g,ew_y,ew_r);
    end
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_traffic_light);
    repeat (3) @(posedge clk);
    rst = 0;

    // Run long enough for two full cycles: (5+2+5+2)=14 ticks per cycle
    // Our tick every 10 clks -> ~280 clks for two cycles; add margin
    repeat (320) @(posedge clk);
    $finish;
end
endmodule