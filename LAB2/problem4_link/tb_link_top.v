// CS322M Problem 4 TB: Master–Slave 4-phase handshake
`timescale 1ns/1ps
module tb_link_top;
reg clk = 0, rst = 1;
wire done;
link_top dut(.clk(clk), .rst(rst), .done(done));

always #5 clk = ~clk; // 100 MHz

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_link_top);
    repeat (3) @(posedge clk);
    rst = 0;

    // Monitor key handshake signals
    $display("time  req ack data   done");
    forever begin
        @(posedge clk);
        $display("%0t  %0b   %0b   0x%0h   %0b",
                 $time, dut.u_master.req, dut.u_slave.ack, dut.u_master.data, done);
        if (done) begin
            // give a few more cycles for visibility
            repeat (2) @(posedge clk);
            $finish;
        end
    end
end
endmodule