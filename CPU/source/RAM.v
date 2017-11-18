module RAM (
    input wire rst,
    input wire clk,
    input wire[31:0] addrIn,
    input wire[15:0] write,
    input wire we,
    output wire[15:0] read,
    input wire re,
    output wire ready,
    output wire[10:0] lcdPins,
    output wire[15:0] page,
    input wire[3:0] switch,

    output wire[31:0] bp0Addr, bp1Addr, bp2Addr, bp3Addr, bpAddr, keyboardAddr, irAddr,
    output wire bp0En, bp1En, bp2En, bp3En, keyboardEn, irEn
    );

wire[31:0] addr = (re || we)? addrIn : 32'h00000000;
wire isStack = addr <= 32'hD000FFFF && addr >= 32'hD0000000;
wire isInstr = addr <= 32'h000FFFFF;
wire isLCD = addr == 32'hFFFF0000 || addr == 32'hFFFF0001;
wire isSwitch = addr == 32'hFFFF0002;
wire isPage = addr == 32'hFFFF1000;
wire isBPRegs = addr >= 32'hFFFFF000 && addr <= 32'hFFFFF00D;
wire isInt = addr >= 32'hFFFFFFFA && addr <= 32'hFFFFFFFF;
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

reg[15:0] keyboardAddrHigh = 16'h0000;
reg[15:0] keyboardAddrLow = 16'h0000;
reg enKeyboard = 1;
assign keyboardAddr = {keyboardAddrHigh, keyboardAddrLow};
assign keyboardEn = enKeyboard;

always @ (posedge clk) begin
    if (rst) begin
        keyboardAddrHigh <= 16'h0000;
        keyboardAddrLow <= 16'h0000;
        enKeyboard <= 1'b1;
    end else if (we && addr == 32'hFFFFFFFD)
        enKeyboard <= |write;
    else if (we && addr == 32'hFFFFFFFE)
        keyboardAddrLow <= write;
    else if (we && addr == 32'hFFFFFFFF)
        keyboardAddrHigh <= write;
end

reg[15:0] irAddrHigh = 16'h0000;
reg[15:0] irAddrLow = 16'h0000;
reg enIR = 1;
assign irAddr = {irAddrHigh, irAddrLow};
assign irEn = enIR;

always @ (posedge clk) begin
    if (rst) begin
        irAddrHigh <= 16'h0000;
        irAddrLow <= 16'h0000;
        enIR <= 1'b1;
    end else if (we && addr == 32'hFFFFFFFA)
        enIR <= |write;
    else if (we && addr == 32'hFFFFFFFB)
        irAddrLow <= write;
    else if (we && addr == 32'hFFFFFFFC)
        irAddrHigh <= write;
end

reg[15:0] breakPoint0High, breakPoint0Low;
reg[15:0] breakPoint1High, breakPoint1Low;
reg[15:0] breakPoint2High, breakPoint2Low;
reg[15:0] breakPoint3High, breakPoint3Low;
reg[15:0] breakPointAddrHigh, breakPointAddrLow;
reg enBreakPoint0, enBreakPoint1, enBreakPoint2, enBreakPoint3;

assign bp0Addr = {breakPoint0High, breakPoint0Low};
assign bp1Addr = {breakPoint1High, breakPoint1Low};
assign bp2Addr = {breakPoint2High, breakPoint2Low};
assign bp3Addr = {breakPoint3High, breakPoint3Low};
assign bpAddr = {breakPointAddrHigh, breakPointAddrLow};
assign bp0En = enBreakPoint0;
assign bp1En = enBreakPoint1;
assign bp2En = enBreakPoint2;
assign bp3En = enBreakPoint3;

always @ (posedge clk) begin
    if (rst) begin
        breakPoint0High <= 16'h0000;
        breakPoint0Low <= 16'h0000;
        breakPoint1High <= 16'h0000;
        breakPoint1Low <= 16'h0000;
        breakPoint2High <= 16'h0000;
        breakPoint2Low <= 16'h0000;
        breakPoint3High <= 16'h0000;
        breakPoint3Low <= 16'h0000;
        breakPointAddrHigh <= 16'h0000;
        breakPointAddrLow <= 16'h0000;
        enBreakPoint0 <= 1'b0;
        enBreakPoint1 <= 1'b0;
        enBreakPoint2 <= 1'b0;
        enBreakPoint3 <= 1'b0;
    end 
    else if (we && addr == 32'hFFFFF000)
        enBreakPoint0 <= |write;
    else if (we && addr == 32'hFFFFF001)
        breakPoint0Low <= write;
    else if (we && addr == 32'hFFFFF002)
        breakPoint0High <= write;
    else if (we && addr == 32'hFFFFF003)
        enBreakPoint1 <= |write;
    else if (we && addr == 32'hFFFFF004)
        breakPoint1Low <= write;
    else if (we && addr == 32'hFFFFF005)
        breakPoint1High <= write;
    else if (we && addr == 32'hFFFFF006)
        enBreakPoint2 <= |write;
    else if (we && addr == 32'hFFFFF007)
        breakPoint2Low <= write;
    else if (we && addr == 32'hFFFFF008)
        breakPoint2High <= write;
    else if (we && addr == 32'hFFFFF009)
        enBreakPoint3 <= |write;
    else if (we && addr == 32'hFFFFF00A)
        breakPoint3Low <= write;
    else if (we && addr == 32'hFFFFF00B)
        breakPoint3High <= write;
    else if (we && addr == 32'hFFFFF00C)
        breakPointAddrLow <= write;
    else if (we && addr == 32'hFFFFF00D)
        breakPointAddrHigh <= write;
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
                isSwitch? switch :
                16'h0000;

reg isReading1 = 0;
reg isReading2 = 0;
reg regReady = 0;
assign ready = 1;

/*always @ (posedge clk)
begin
    isReading1 <= re;
    isReading2 <= isReading1;
    if (isReading1 && !isReading2)
       regReady <= 1;
    else if (!isReading1 && isReading2)
        regReady <= 0;
    else if (isReading1 && isReading2)
    regReady <= !regReady;
end*/

endmodule
