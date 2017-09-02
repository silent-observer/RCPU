/*
 * Standard RAM interface (with asyncroneous read)
 * With reset
 */

module RAM (
    input wire rst,
    input wire clk,
    input wire[addrSize-1:0] addr,
    input wire[wordSize-1:0] wdata,
    input wire we,
    output wire[wordSize-1:0] rdata);

parameter addrSize = 16; // Address bus width
parameter wordSize = 16; // Data bus width
parameter depth = 1 << addrSize;



reg[wordSize-1:0] memory[0:depth-1];

assign rdata = memory[addr];

integer i;

always @ (posedge clk or posedge rst)
    if (rst) // Set every cell to 0
        for (i = 0; i < depth; i = i + 1)
            memory[i] <= 0;
    else if (we)
        memory[addr] <= wdata;
endmodule
