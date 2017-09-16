/*
 * Standard RAM interface (with registered inputs and delay)
 * With reset
 */

`timescale 1 us / 1 us

module RAM2 (
    input wire rst,
    input wire clk,
    input wire[addrSize-1:0] addr,
    input wire[wordSize-1:0] wdata,
    input wire we,
    input wire re,
    output wire[wordSize-1:0] rdata,
    output reg ready);

parameter addrSize = 16; // Address bus width
parameter wordSize = 16; // Data bus width
parameter depth = 1 << addrSize;

reg[addrSize-1:0] regAddr;
reg[wordSize-1:0] regWData;
reg regWE;
reg isReading1;
reg isReading2;

always @ (posedge clk or posedge rst)
    if (rst) begin
        regAddr <= {addrSize{1'b0}};
        regWData <= {wordSize{1'b0}};
        regWE <= 0;
    end else begin
        regAddr <= addr;
        regWData <= wdata;
        regWE <= we;
    end

always @ (posedge clk or posedge rst)
    if (rst) begin
        isReading1 <= 0;
        isReading2 <= 0;
        ready <= 0;
    end else begin
        isReading1 <= re;
        isReading2 <= isReading1;
        if (isReading1 && !isReading2)
            ready <= 1;
        else if (!isReading1 && isReading2)
            ready <= 0;
        else if (isReading1 && isReading2)
            ready <= !ready;
    end

reg[wordSize-1:0] memory[0:depth-1];

assign #7 rdata = memory[regAddr];

integer i;

always @ (posedge clk or posedge rst)
    if (rst) // Set every cell to 0
        for (i = 0; i < depth; i = i + 1)
            memory[i] <= 0;

    else if (regWE)
        memory[regAddr] <= #7 regWData;
endmodule
