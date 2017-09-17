module RAM (
	input wire rst,
	input wire clk,
	input wire[31:0] addr,
	input wire[15:0] write,
	input wire we,
	output wire[15:0] read,
	input wire re,
	output wire ready,
	output wire[10:0] lcdPins,
	output wire[31:0] intAddr
	);

wire isStack = addr <= 16'hD000 && addr > 16'hC000;
wire isInstr = addr <= 16'h0100;
wire isLCD = addr == 16'hF000 || addr == 16'hF001;
wire isInt = addr == 16'hFFFE || addr == 16'hFFFF;

wire[15:0] romOut, ramOut;

InstrROM rom (
	.address (addr[7:0]),
	.clock (clk),
	.q (romOut)
	);

wire[15:0] stackAddr = 	16'hD000 - addr[15:0];

StackRAM ram (
	.address (stackAddr[9:0]),
	.clock (clk),
	.data (write),
	.wren (we && isStack),
	.q (ramOut)
	);

reg[7:0] lcdData = 8'h00;
reg[2:0] lcdCtrl = 3'b000;
assign lcdPins = {lcdCtrl, lcdData};

always @ (posedge clk) begin
	if (rst) begin
		lcdData <= 8'h00;
		lcdCtrl <= 4'b000;
	end else if (we && addr == 16'hF000)
		lcdData <= write[7:0];
	else if (we && addr == 16'hF001)
		lcdCtrl <= write[2:0];
end

reg[15:0] interruptHigh = 16'h0000;
reg[15:0] interruptLow = 16'h0000;
assign intAddr = {interruptHigh, interruptLow};

always @ (posedge clk) begin
	if (rst) begin
		interruptHigh <= 16'h0000;
		interruptLow <= 16'h0000;
	end else if (we && addr == 16'hFFFE)
		interruptLow <= write;
	else if (we && addr == 16'hFFFF)
		interruptHigh <= write;
end


assign read = 	isStack? ramOut :
					isInstr? romOut :
					isLCD? 16'h0000 :
					isInt? 16'h0000 :
					16'h0000;

reg isReading1 = 0;
reg isReading2 = 0;
reg regReady = 0;
assign ready = 1;

always @ (posedge clk)
begin
	isReading1 <= re;
	isReading2 <= isReading1;
	if (isReading1 && !isReading2)
	   regReady <= 1;
	else if (!isReading1 && isReading2)
		regReady <= 0;
	else if (isReading1 && isReading2)
	regReady <= !regReady;
end
					

endmodule
