module RAM ( // Random Access Memory Emulation
    input wire rst, // Reset
    input wire clk, // Clock
    input wire[addrSize-1:0] addr, // Address
    input wire[wordSize-1:0] wdata, // Data for writing
    input wire we, // Write enable
    output wire[wordSize-1:0] rdata); // Asynchronous read

parameter addrSize = 16; // Address bus width
parameter wordSize = 16; // Data bus width
parameter depth = 1 << addrSize;



reg[wordSize-1:0] memory[0:depth-1]; // Main memory

assign rdata = memory[addr];  // Asynchronous read

integer i;

always @ (posedge clk or posedge rst)
    if (rst) // Set every cell to 0
        for (i = 0; i < depth; i = i + 1)
            memory[i] <= 0;
    else if (we) // Set cell memory[addr] to wdata
        memory[addr] <= wdata;
endmodule
