// Truth table:
// A B | o1 o2 o3
// 0 0 |  0  1  0
// 0 1 |  0  0  1
// 1 0 |  1  0  0
// 1 1 |  0  1  0


module comparator1bit(
    input  A,
    input  B,
    output o1,  // A > B
    output o2,  // A == B
    output o3   // A < B
);
    assign o1 = A & ~B;
    assign o2 = ~(A ^ B);
    assign o3 = ~A & B;
endmodule