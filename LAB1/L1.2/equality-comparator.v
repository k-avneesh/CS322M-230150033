module equality4bit(
    input  [3:0] A,
    input  [3:0] B,
    output  eq
);
    assign eq = (A==B);
endmodule