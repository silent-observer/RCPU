`ifdef __ICARUS__
`include "../source/register.v"
`include "../source/gpuController.v"
`endif

module rgpu (
    input wire clk,
    input wire rst,
    input wire[15:0] memRead,
    output reg[15:0] memAddr,
    output wire memRE,

    input wire[15:0] sNT,
    input wire[15:0] sNP,
    input wire[15:0] sNPL,
    output wire hSync,
    output wire vSync,

    output wire[3:0] r,
    output wire[3:0] g,
    output wire[3:0] b
    );

wire[47:0] currPalette;
wire[15:0] nextPalette1;
wire[15:0] nextPalette2;
wire[15:0] nextPalette3;
wire enCP, enNP1, enNP2, enNP3;
register #(48) rCP (clk, {nextPalette1, nextPalette2, nextPalette3},
    currPalette, enCP, rst);
register #(16) rNP1 (clk, memRead, nextPalette1, enNP1, rst);
register #(16) rNP2 (clk, memRead, nextPalette2, enNP2, rst);
register #(16) rNP3 (clk, memRead, nextPalette3, enNP3, rst);

wire[15:0] currTile;
wire[15:0] nextTile;
wire[15:0] currPixelLine;
wire[15:0] nextPixelLine;
wire enCT, enNT, enCPL, enNPL;
register #(16) rCT (clk, nextTile, currTile, enCT, rst);
register #(16) rNT (clk, memRead, nextTile, enNT, rst);
register #(16) rCPL (clk, nextPixelLine, currPixelLine, enCPL, rst);
register #(16) rNPL (clk, memRead, nextPixelLine, enNPL, rst);

wire nextLine, nextFrame, blank;
wire[9:0] xPos, yPos;
wire[2:0] memAddrSource;

gpuController gpuCTRL (
    .clk (clk),
    .rst (rst),
    .enCP (enCP),
    .enNP1 (enNP1),
    .enNP2 (enNP2),
    .enNP3 (enNP3),
    .enCT (enCT),
    .enNT (enNT),
    .enCPL (enCPL),
    .enNPL (enNPL),
    .nextLine (nextLine),
    .nextFrame (nextFrame),
    .xPosOut (xPos),
    .yPosOut (yPos),
    .memAddr (memAddrSource),
    .hSync (hSync),
    .vSync (vSync),
    .blank (blank),
    .re (memRE)
    );

wire[9:0] loadingX = nextLine ? 0 : xPos + 8;
wire[9:0] loadingY = nextFrame? 0: (nextLine ? yPos + 1 : yPos);

wire[15:0] loadNT = sNT + loadingY[9:3]*80 + loadingX[9:3];
wire[15:0] loadNP1 = sNP + (nextTile[15:9] * 3) + 0;
wire[15:0] loadNP2 = sNP + (nextTile[15:9] * 3) + 1;
wire[15:0] loadNP3 = sNP + (nextTile[15:9] * 3) + 2;
wire[15:0] loadNPL = sNPL + (nextTile[8:0] << 3) + loadingY[2:0];

always @ ( * ) begin
    case (memAddrSource)
        0: memAddr = loadNT;
        1: memAddr = loadNP1;
        2: memAddr = loadNP2;
        3: memAddr = loadNP3;
        4: memAddr = loadNPL;
        default: memAddr = 0;
    endcase
end

wire[1:0] pixelData = currPixelLine[(7 - (xPos & 7)) << 1 +: 2];
wire[11:0] colorData = currPalette[pixelData*12 +: 12];

assign {r, g, b} = blank? 12'b0 : colorData;

endmodule
