// CS322M Problem 4: Slave FSM
// On req high: latch data_in, assert ack for >=2 cycles; after 2 cycles and once req is low, deassert ack.
module slave_fsm(
input wire clk,
input wire rst, // sync
input wire req,
input wire [7:0] data_in,
output reg ack,
output reg [7:0] last_byte
);
localparam [1:0] WAIT_REQ = 2'd0,
ASSERT_ACK = 2'd1,
AFTER_2 = 2'd2,
DROP_ACK = 2'd3;

reg [1:0] state, next_state;
reg [1:0] hold_cnt; // count 0..1 (2 cycles)

// Next-state logic
always @* begin
    next_state = state;
    case (state)
        WAIT_REQ:   if (req) next_state = ASSERT_ACK;
        ASSERT_ACK: if (hold_cnt == 2'd1) next_state = AFTER_2;
        AFTER_2:    if (!req) next_state = DROP_ACK; // wait for master to drop req
        DROP_ACK:   next_state = WAIT_REQ;
        default:    next_state = WAIT_REQ;
    endcase
end

// Registers & outputs
always @(posedge clk) begin
    if (rst) begin
        state <= WAIT_REQ;
        hold_cnt <= 2'd0;
        ack <= 1'b0;
        last_byte <= 8'h00;
    end else begin
        state <= next_state;
        case (state)
            WAIT_REQ: begin
                ack <= 1'b0;
                hold_cnt <= 2'd0;
                if (req) begin
                    last_byte <= data_in; // latch when request observed
                end
            end
            ASSERT_ACK: begin
                ack <= 1'b1;
                hold_cnt <= hold_cnt + 1'b1; // will count 0,1 for 2 cycles
            end
            AFTER_2: begin
                ack <= 1'b1; // keep high until req is low
            end
            DROP_ACK: begin
                ack <= 1'b0;
            end
        endcase
    end
end

endmodule