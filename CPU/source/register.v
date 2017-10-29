/*
 * Universal register module
 * Asyncroneous read, syncroneous write
 */
module register(
    input wire clk,
    input wire[N-1:0] in,
    output wire[N-1:0] out,
    input wire en,
    input wire rst);

parameter N = 16; // Width

reg[N-1:0] value;

always @ (posedge clk)
    if (rst)
        value <= 0;
    else if (en)
        value <= in;

assign out = value;

endmodule
