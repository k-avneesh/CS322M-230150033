module traffic_light(
input wire clk,
input wire rst, // sync active-high
input wire tick, // 1-cycle pulse
output reg ns_g, ns_y, ns_r,
output reg ew_g, ew_y, ew_r
);
localparam [1:0] NS_G = 2'd0,
NS_Y = 2'd1,
EW_G = 2'd2,
EW_Y = 2'd3;

// Duration per state (in ticks)
localparam integer T_NS_G = 5;
localparam integer T_NS_Y = 2;
localparam integer T_EW_G = 5;
localparam integer T_EW_Y = 2;

reg [1:0] state, next_state;
reg [3:0] tick_cnt; // enough for up to 15 ticks

// Next-state computation (combinational)
always @* begin
    next_state = state;
    case (state)
        NS_G: if (tick && tick_cnt == T_NS_G-1) next_state = NS_Y;
        NS_Y: if (tick && tick_cnt == T_NS_Y-1) next_state = EW_G;
        EW_G: if (tick && tick_cnt == T_EW_G-1) next_state = EW_Y;
        EW_Y: if (tick && tick_cnt == T_EW_Y-1) next_state = NS_G;
        default: next_state = NS_G;
    endcase
end

// State/timer registers and outputs
always @(posedge clk) begin
    if (rst) begin
        state <= NS_G;
        tick_cnt <= 0;
    end else begin
        // tick counter
        if (tick) begin
            // At completion, reset counter for next state on same cycle
            if ( (state==NS_G && tick_cnt==T_NS_G-1) ||
                 (state==NS_Y && tick_cnt==T_NS_Y-1) ||
                 (state==EW_G && tick_cnt==T_EW_G-1) ||
                 (state==EW_Y && tick_cnt==T_EW_Y-1) ) begin
                tick_cnt <= 0;
            end else begin
                tick_cnt <= tick_cnt + 1'b1;
            end
        end
        // advance state
        state <= next_state;
    end
end

// Moore outputs based on state (one of g/y/r high per road)
always @* begin
    // defaults
    ns_g=0; ns_y=0; ns_r=0;
    ew_g=0; ew_y=0; ew_r=0;
    case (state)
        NS_G: begin ns_g=1; ew_r=1; end
        NS_Y: begin ns_y=1; ew_r=1; end
        EW_G: begin ew_g=1; ns_r=1; end
        EW_Y: begin ew_y=1; ns_r=1; end
        default: begin ns_r=1; ew_r=1; end
    endcase
end
endmodule