// CS322M Problem 3: Mealy vending machine with change
// Price=20. Coins: coin[1:0] 01=5, 10=10, 00=idle (11 ignored).
// When total >= 20: dispense=1 for 1 cycle. If total==25: chg5=1 for 1 cycle. Reset total after vend.
module vending_mealy(
input wire clk,
input wire rst, // sync active-high
input wire [1:0] coin, // 01=5, 10=10, 00=idle
output reg dispense, // pulse
output reg chg5 // pulse
);
localparam [1:0] S0 = 2'd0, // total 0
S5 = 2'd1, // total 5
S10= 2'd2, // total 10
S15= 2'd3; // total 15
reg [1:0] state, next_state;

// Decode coin value
wire is5  = (coin == 2'b01);
wire is10 = (coin == 2'b10);
wire idle = (coin == 2'b00) || (coin == 2'b11);

// Next-state logic (combinational)
always @* begin
    next_state = state;
    case (state)
        S0:  begin
                if (is5)      next_state = S5;
                else if (is10)next_state = S10;
             end
        S5:  begin
                if (is5)      next_state = S10;
                else if (is10)next_state = S15;
             end
        S10: begin
                if (is5)      next_state = S15;
                else if (is10)next_state = S0; // vend (20), reset
             end
        S15: begin
                if (is5)      next_state = S0; // vend (20), reset
                else if (is10)next_state = S0; // vend (25), reset (with change)
             end
        default: next_state = S0;
    endcase
end

// State register + Mealy pulses (registered, 1-cycle)
always @(posedge clk) begin
    if (rst) begin
        state <= S0;
        dispense <= 1'b0;
        chg5 <= 1'b0;
    end else begin
        dispense <= 1'b0;
        chg5 <= 1'b0;
        // Vend conditions on observing coin at current state
        case (state)
            S10: if (is10) begin
                      dispense <= 1'b1; // 10+10=20
                  end
            S15: if (is5) begin
                      dispense <= 1'b1; // 15+5=20
                  end else if (is10) begin
                      dispense <= 1'b1; // 15+10=25
                      chg5    <= 1'b1;
                  end
        endcase
        state <= next_state;
    end
end
endmodule