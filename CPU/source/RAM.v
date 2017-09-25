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
    output wire[31:0] intAddr,
    output wire[15:0] page,
    output reg intEn
    );

wire isStack = addr <= 32'hD000FFFF && addr >= 32'hD0000000;
wire isInstr = addr <= 32'h000FFFFF;
wire isLCD = addr == 32'hFFFF0000 || addr == 32'hFFFF0001;
wire isPage = addr == 32'hFFFF1000;
wire isInt = addr >= 32'hFFFFFFFD || addr <= 32'hFFFFFFFF;
wire isHeap = addr <= 32'h8FFFFFFF && addr >= 32'h10000000;

wire[15:0] romOut, ram1Out, ram2Out;

InstrROM rom (
    .address (addr[9:0]),
    .clock (clk),
    .q (romOut)
    );

wire[15:0] stackAddr = addr[15:0];

StackRAM ram1 (
    .address (stackAddr[9:0]),
    .clock (clk),
    .data (write),
    .wren (we && isStack),
    .q (ram1Out)
    );

wire[30:0] heapAddr = addr[30:0];

HeapRAM ram2 (
    .address (heapAddr[11:0]),
    .clock (clk),
    .data (write),
    .wren (we && isHeap),
    .q (ram2Out)
    );

reg[7:0] lcdData = 8'h00;
reg[2:0] lcdCtrl = 3'b000;
assign lcdPins = {lcdCtrl, lcdData};

always @ (posedge clk) begin
    if (rst) begin
        lcdData <= 8'h00;
        lcdCtrl <= 4'b000;
    end else if (we && addr == 32'hFFFF0000)
        lcdData <= write[7:0];
    else if (we && addr == 32'hFFFF0001)
        lcdCtrl <= write[2:0];
end

reg[15:0] interruptHigh = 16'h0000;
reg[15:0] interruptLow = 16'h0000;
assign intAddr = {interruptHigh, interruptLow};

always @ (posedge clk) begin
    if (rst) begin
        interruptHigh <= 16'h0000;
        interruptLow <= 16'h0000;
        intEn <= 1'b1;
    end else if (we && addr == 32'hFFFFFFFD)
        intEn <= |write;
    else if (we && addr == 32'hFFFFFFFE)
        interruptLow <= write;
    else if (we && addr == 32'hFFFFFFFF)
        interruptHigh <= write;
end

reg[15:0] pageReg = 16'h0000;
assign page = pageReg;

always @ (posedge clk) begin
    if (rst) begin
        pageReg <= 16'h0000;
    end else if (we && addr == 32'hFFFF1000)
        pageReg <= write;
end


assign read =   isStack? ram1Out :
                isHeap? ram2Out :
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
