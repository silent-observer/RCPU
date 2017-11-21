module RS232Controller (
    input wire clk,
    input wire rst,
    input wire rs232RX,
    output wire rs232TX,
    output wire[7:0] rxData,
    output wire rxReady,
    input wire[7:0] txData,
    input wire txStart,
    output wire txBusy
    );


wire bps1, startBPS1;
RS232BaudRateController baud1 (clk, rst, startBPS1, bps1);
RS232RX rx (
    .clk (clk),
    .rst (rst),
    .rs232RX (rs232RX),
    .data (rxData),
    .ready (rxReady),
    .bps (bps1),
    .startBPS (startBPS1)
    );

wire bps2, startBPS2;
RS232BaudRateController baud2 (clk, rst, startBPS2, bps2);
RS232TX tx (
    .clk (clk),
    .rst (rst),
    .rs232TX (rs232TX),
    .data (txData),
    .startTX (txStart),
    .busy (txBusy),
    .bps (bps2),
    .startBPS (startBPS2)
    );

endmodule
