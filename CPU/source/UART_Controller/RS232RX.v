module RS232RX (
    input wire clk,
    input wire rst,
    input wire rs232RX,
    output reg[7:0] data,
    output reg ready,
    input wire bps,
    output reg startBPS
    );

reg rx0, rx1, rx2, rx3;
always @(posedge clk) begin
    if (rst) begin
        rx0 <= 1'b0;
        rx1 <= 1'b0;
        rx2 <= 1'b0;
        rx3 <= 1'b0;
    end else begin
        rx0 <= rs232RX;
        rx1 <= rx0;
        rx2 <= rx1;
        rx3 <= rx2;
    end
end

wire rxNegEdge = rx3 & rx2 & ~rx1 & ~rx0;

reg[3:0] state;

always @(posedge clk) begin
    if (rst) begin
        startBPS <= 1'b0;
        ready <= 1'b0;
    end else if (rxNegEdge) begin
        startBPS <= 1'b1;
        ready <= 1'b0;
    end else if (state == 4'd10) begin
        startBPS <= 1'b0;
        ready <= 1'b1;
    end
end

reg[7:0] dataTemp;
always @(posedge clk) begin
    if (rst) begin
        dataTemp <= 8'b0;
        data <= 8'b0;
        state <= 4'b0;
    end else if (startBPS) begin
        if (bps) begin
            state <= state + 4'b1;
            case (state)
                4'd1: dataTemp[0] <= rs232RX;
                4'd2: dataTemp[1] <= rs232RX;
                4'd3: dataTemp[2] <= rs232RX;
                4'd4: dataTemp[3] <= rs232RX;
                4'd5: dataTemp[4] <= rs232RX;
                4'd6: dataTemp[5] <= rs232RX;
                4'd7: dataTemp[6] <= rs232RX;
                4'd8: dataTemp[7] <= rs232RX;
            endcase
        end else if (state == 4'd10) begin
            state <= 4'b0;
            data <= dataTemp;
        end
    end
end

endmodule