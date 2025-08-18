// CS322M Problem 4: Master FSM (4-byte burst A0..A3)
// 4-phase handshake: Master drives data, raises req; waits ack; drops req; waits ack low; repeat.
// 'done' pulses 1 cycle after the 4th byte handshake completes.
module master_fsm(
input wire clk,
input wire rst, // sync
input wire ack,
output reg req,
output reg [7:0] data,
output reg done // 1-cycle pulse when burst completes
);
localparam [2:0] IDLE=3'd0, REQ_H=3'd1, WAIT_ACK=3'd2, DROP_REQ=3'd3, WAIT_ACK_LO=3'd4, DONE=3'd5;

reg [2:0] state, next_state;
reg [1:0] idx; // 0..3

// Next state
always @* begin
    next_state = state;
    case (state)
        IDLE:       next_state = REQ_H;
        REQ_H:      next_state = ack ? WAIT_ACK : REQ_H;
        WAIT_ACK:   next_state = DROP_REQ; // ack just observed; keep req high this cycle
        DROP_REQ:   next_state = WAIT_ACK_LO;
        WAIT_ACK_LO:begin
                        if (!ack) begin
                            if (idx == 2'd3) next_state = DONE;
                            else             next_state = REQ_H;
                        end
                    end
        DONE:       next_state = DONE;
        default:    next_state = IDLE;
    endcase
end

// Output & registers
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        idx   <= 2'd0;
        req   <= 1'b0;
        data  <= 8'hA0;
        done  <= 1'b0;
    end else begin
        done <= 1'b0; // default
        state <= next_state;

        case (state)
            IDLE: begin
                // load first byte
                idx  <= 2'd0;
                data <= 8'hA0;
                req  <= 1'b0;
            end
            REQ_H: begin
                req <= 1'b1; // drive data & req high until ack
            end
            WAIT_ACK: begin
                req <= 1'b1; // still high for one cycle to allow slave to see it
            end
            DROP_REQ: begin
                req <= 1'b0;
            end
            WAIT_ACK_LO: begin
                if (!ack) begin
                    // prepare next byte
                    if (idx != 2'd3) begin
                        idx  <= idx + 1'b1;
                        data <= 8'hA0 + {6'd0, idx} + 8'h01; // A0, A1, A2, A3
                        // Note: 'data' advances at the moment we schedule next REQ_H
                    end
                end
            end
            DONE: begin
                done <= 1'b1; // single-cycle pulse
                req  <= 1'b0;
            end
        endcase
    end
end

endmodule