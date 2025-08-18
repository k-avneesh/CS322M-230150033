// CS322M Problem 4: Top-level connecting master and slave
module link_top(
input wire clk,
input wire rst,
output wire done
);
wire req, ack;
wire [7:0] data_bus;
master_fsm u_master(.clk(clk), .rst(rst), .ack(ack), .req(req), .data(data_bus), .done(done));
slave_fsm  u_slave (.clk(clk), .rst(rst), .req(req), .data_in(data_bus), .ack(ack), .last_byte());
endmodule