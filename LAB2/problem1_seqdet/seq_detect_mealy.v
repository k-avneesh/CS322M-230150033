module seq_detect_mealy(
    input  wire clk,
    input  wire rst,   // sync active-high
    input  wire din,   // serial input bit per clock
    output reg  y      // 1-cycle pulse at detection
);
    localparam [1:0] S0   = 2'd0, // no match
                     S1   = 2'd1, // seen '1'
                     S11  = 2'd2, // seen '11'
                     S110 = 2'd3; // seen '110'
    reg [1:0] state, next_state;

    // Next-state logic
    always @* begin
        case (state)
            S0:    next_state = din ? S1   : S0;
            S1:    next_state = din ? S11  : S0;
            S11:   next_state = din ? S11  : S110;
            S110:  next_state = din ? S1   : S0;   // on '1' we also fire output
            default: next_state = S0;
        endcase
    end

    // State register
    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
            y <= 1'b0;
        end else begin
            y <= 1'b0;
            // Pulse when (pattern 1101 complete)
            if (state == S110 && din) y <= 1'b1;
            state <= next_state;
        end
    end
endmodule