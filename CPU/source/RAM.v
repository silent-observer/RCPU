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
    output wire[31:0] intAddr,
    output wire[15:0] page,
    output reg intEn,
    output wire[15:0] bpData,
    output wire isBP,
    input wire[3:0] switch,
    output reg[15:0] breakPointAddrHigh, 
    output reg[15:0] breakPointAddrLow
    );

wire[31:0] addr = (re || we)? addrIn : 32'h00000000;
wire isStack = addr <= 32'hD000FFFF && addr >= 32'hD0000000;
wire isInstr = addr <= 32'h000FFFFF;
wire isLCD = addr == 32'hFFFF0000 || addr == 32'hFFFF0001;
wire isSwitch = addr == 32'hFFFF0002;
wire isPage = addr == 32'hFFFF1000;
wire isBPRegs = addr >= 32'hFFFFF000 || addr <= 32'hFFFFF00D;
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

reg[15:0] breakPoint0High, breakPoint0Low;
reg[15:0] breakPoint1High, breakPoint1Low;
reg[15:0] breakPoint2High, breakPoint2Low;
reg[15:0] breakPoint3High, breakPoint3Low;
//reg[15:0] breakPointAddrHigh, breakPointAddrLow;
reg enBreakPoint0, enBreakPoint1, enBreakPoint2, enBreakPoint3;

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

wire isBP0 = (addr == {breakPoint0High, breakPoint0Low}) & enBreakPoint0;
wire isBP1 = (addr == {breakPoint1High, breakPoint1Low}) & enBreakPoint1;
wire isBP2 = (addr == {breakPoint2High, breakPoint2Low}) & enBreakPoint2;
wire isBP3 = (addr == {breakPoint3High, breakPoint3Low}) & enBreakPoint3;
assign isBP = (isBP0 | isBP1 | isBP2 | isBP3) & (re | we);

assign bpData = isBP0? 16'd0 :
                isBP1? 16'd1 :
                isBP2? 16'd2 :
                isBP3? 16'd3 : 16'd0;
assign intAddr = isBP? {breakPointAddrHigh, breakPointAddrLow} : {interruptHigh, interruptLow};

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
