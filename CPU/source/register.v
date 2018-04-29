/*
 * Universal register module
 * Asyncroneous read, syncroneous write
 */
module register(
    input wire clk,
    input wire[N-1:0] in,
    output wire[N-1:0] out,
    input wire en,
    input wire rst,
    input wire[1:0] inMask,
    input wire[1:0] outMask);

parameter N = 16; // Width

reg[N-1:0] value;

wire[N/2-1:0] halfIn = (inMask == 2'b01)? in[N/2-1:0]:
                     (inMask == 2'b10)? in[N-1:N/2]:
                     {N/2{1'b0}};

always @ (posedge clk)
    if (rst)
        value <= 0;
    else if (en) begin
        if (inMask == 2'b11 || outMask == 2'b11)
            value <= in;
        else if (outMask == 2'b01)
            value[N/2-1:0] <= halfIn;
        else if (outMask == 2'b10)
            value[N-1:N/2] <= halfIn;
    end

assign out = value;

endmodule
