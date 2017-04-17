module  gpuController( // GPU control unit (FMA)
    input wire clk, // Clock
    input wire rst, // Reset

    output reg[2:0] memAddr, // Source of memory address
    output reg enCP,
    output reg enNP1,
    output reg enNP2,
    output reg enNP3,
    output reg enCT,
    output reg enNT,
    output reg enCPL,
    output reg enNPL,
    output wire hSync,
    output wire vSync,
    output wire blank,
    output wire nextLine,
    output wire nextFrame,
    output wire[9:0] xPosOut,
    output wire[9:0] yPosOut,
    output reg re
    );

reg[9:0] xPos;
reg[9:0] yPos;

assign xPosOut = xPos;
assign yPosOut = yPos;


always @ (posedge clk or posedge rst) begin // FMS sequential logic
    if (rst) begin // Reset of all state registes
        xPos <= 640;
        yPos <= 480;
    end else if (xPos < 800-1) begin
        xPos <= xPos + 1; // Go to next pixel
    end else if (yPos < 525-1) begin
        yPos <= yPos + 1; // Go to next line
        xPos <= 0;
    end else begin
        yPos <= 0; // Go to next frame
        xPos <= 0;
    end
end

assign hSync = !(xPos >= 656 && xPos < 752);
assign vSync = !(yPos >= 490 && yPos < 492);
assign blank = xPos >= 640 || yPos >= 480;
assign nextLine = xPos >= 632 && xPos < 640;
assign nextFrame = yPos >= 472 && yPos < 480 && nextLine;

always @ ( * ) begin
    enCP = 0;
    enNP1 = 0;
    enNP2 = 0;
    enNP3 = 0;
    enCT = 0;
    enNT = 0;
    enCPL = 0;
    enNPL = 0;
    memAddr = 0;
    re = 0;
    if (!blank)
        case (xPos[2:0])
            0: begin enNT = 1; memAddr = 0; re = 1; end
            1: begin enNP1 = 1; memAddr = 1; re = 1; end
            2: begin enNP2 = 1; memAddr = 2; re = 1; end
            3: begin enNP3 = 1; memAddr = 3; re = 1; end
            4: begin enNPL = 1; memAddr = 4; re = 1; end
            7: begin
                enCP = 1;
                enCT = 1;
                enCPL = 1;
            end
        endcase
end

endmodule
