module RS232TX (
    input wire clk,
    input wire rst,
    output reg rs232TX,
    input wire[7:0] data,
    input wire startTX,
    output reg busy,
    input wire bps,
    output reg startBPS
    );

reg startTX0, startTX1, startTX2;
always @(posedge clk) begin
    if (rst) begin
        startTX0 <= 1'b0;
        startTX1 <= 1'b0;
        startTX2 <= 1'b0;
    end else begin
        startTX0 <= startTX;
        startTX1 <= startTX0;
        startTX2 <= startTX1;
    end
end
wire startTXPosEdge = ~startTX2 & startTX1;

reg[7:0] txData;
reg[3:0] state;

always @(posedge clk) begin
    if (rst) begin
        startBPS <= 1'b0;
        busy <= 1'b0;
        txData <= 8'b0;
    end else if (startTXPosEdge) begin
        startBPS <= 1'b1;
        txData <= data;
        busy <= 1'b1;
    end else if (state == 4'd11) begin
        startBPS <= 1'b0;
        busy <= 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= 4'b0;
        rs232TX <= 1'b1;
    end
    else if (busy) begin
        if (bps) begin
            state <= state + 1;
            case (state)
                4'd0: rs232TX <= 1'b0;
                4'd1: rs232TX <= txData[0];
                4'd2: rs232TX <= txData[1];
                4'd3: rs232TX <= txData[2];
                4'd4: rs232TX <= txData[3];
                4'd5: rs232TX <= txData[4];
                4'd6: rs232TX <= txData[5];
                4'd7: rs232TX <= txData[6];
                4'd8: rs232TX <= txData[7];
                4'd9: rs232TX <= 1'b1;
                default: rs232TX <= 1'b1;
            endcase
        end else if (state == 4'd11) state <= 4'd0;
    end
end

endmodule
