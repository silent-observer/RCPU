`ifdef __ICARUS__
`include "RAM.v"
`endif

module cache (
    input wire rst,
    input wire clk,
    input wire[A-1:0] addr,
    input wire re,
    output wire hit,
    output wire[D-1:0] read
    );

parameter eC = 13;
parameter ew = 2;
parameter eB = eC - ew;
parameter eS = eB - 1;
parameter A = 32;
parameter D = 16;
parameter entrySize = D*(1 << ew);
parameter tagSize = A - (1 << eS) - (1 << ew);
parameter totalSize = 3 + 2*(tagSize + entrySize);

wire [tagSize-1:0] tag;
wire [1 << eS : 0] set;
wire [1 << ew : 0] block;

assign {tag, set, block} = addr;


wire [1 << eS : 0] memAddr = set;
wire [D-1:0] memWData = 16'b0;
wire [D-1:0] memRData;
wire memWE = 0;

RAM #(eS, totalSize) memory (rst, clk, memAddr, memWData, memWE, memRData);

wire [tagSize-1:0] rdTag0;
wire [tagSize-1:0] rdTag1;
wire used, valid0, valid1;
wire [entrySize-1:0] way0, way1;

assign {used, valid0, valid1, rdTag0, way0, rdTag1, way1} = memRData;

wire hit0 = valid0 && rdTag0 == tag;
wire hit1 = valid1 && rdTag1 == tag;
assign hit = hit0 || hit1;

wire [D-1:0] data0 = way0[block*D +: D];
wire [D-1:0] data1 = way1[block*D +: D];
wire [D-1:0] data = hit0? data0 :
                    hit1? data1 : 0;
assign read = re? data : 16'bx;
endmodule
