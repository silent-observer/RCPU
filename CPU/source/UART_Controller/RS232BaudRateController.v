module RS232BaudRateController (
    input wire clk,
    input wire rst,
    input wire startBPS,
    output reg bps 
    );

reg[12:0] counter;

always @(posedge clk) begin
    if (rst) counter <= 13'b0;
    else if ((counter == 13'd5207) || !startBPS) counter <= 13'b0;
    else counter <= counter + 13'b1;
end

always @(posedge clk) begin
    if (rst) bps <= 1'b0;
    else if (counter == 13'd2603 && startBPS) bps <= 1'b1;
    else bps <= 1'b0;
end

endmodule