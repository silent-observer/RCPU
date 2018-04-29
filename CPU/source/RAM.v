module RAM (
    input wire rst,
    input wire clk,
    input wire[31:0] addrIn,
    input wire[15:0] write,
    input wire we,
    output wire[15:0] read,
    input wire re,
    input wire[1:0] inMask,
    input wire[1:0] outMask,

    output wire ready,
    output wire[10:0] lcdPins,
    output wire[15:0] page,
    input wire[3:0] switch,

    output wire[31:0] bp0Addr, bp1Addr, bp2Addr, bp3Addr, bpAddr, keyboardAddr, irAddr,
    output wire bp0En, bp1En, bp2En, bp3En, keyboardEn, irEn,

    output wire[15:0] lcdIn
    );

wire[31:0] addr = (re || we)? addrIn : 32'h00000000;
wire isStack = addr <= 32'hD000FFFF && addr >= 32'hD0000000;
wire isInstr = addr <= 32'h000FFFFF;
wire isLCD = addr == 32'hFFFF0000 || addr == 32'hFFFF0001;
wire isSwitch = addr == 32'hFFFF0002;
wire isFastMem = addr >= 32'hFFFF1000 && addr <= 32'hFFFF101F;
wire isBPRegs = addr >= 32'hFFFFF000 && addr <= 32'hFFFFF015;
wire isInt = addr >= 32'hFFFFFFF6 && addr <= 32'hFFFFFFFF;
wire isHeap = addr <= 32'h8FFFFFFF && addr >= 32'h10000000;

wire[15:0] romOut, ram1Out, ram2Out;

wire[1:0] addrLeast = {2{addr[0]}};

wire[7:0] write8 = (inMask == 2'b01)? write[7:0] :
                   (inMask == 2'b10)? write[15:8] :
                   write[7:0];
wire[15:0] write8S = outMask == (2'b01 ^ addrLeast)? {8'h00, write8} :
                     outMask == (2'b10 ^ addrLeast)? {write8, 8'h00} :
                     addrLeast? {write[7:0], write[15:8]} : write;
wire[15:0] mask = {{8{byteenable[1]}}, {8{byteenable[0]}}};
wire[1:0] byteenable = addrLeast? {outMask[0], outMask[1]}: outMask;

InstrROM rom (
    .address (addr[10:1]),
    .clock (clk),
    .q (romOut)
    );

wire[15:0] stackAddr = addr[15:0];

StackRAM ram1 (
    .address (stackAddr[10:1]),
    .clock (clk),
    .data (write8S),
    .wren (we && isStack),
    .byteena(byteenable),
    .q (ram1Out)
    );

wire[30:0] heapAddr = addr[30:0];

HeapRAM ram2 (
    .address (heapAddr[12:1]),
    .clock (clk),
    .data (write8S),
    .wren (we && isHeap),
    .byteena(byteenable),
    .q (ram2Out)
    );

reg[7:0] lcdData = 8'h00;
reg[2:0] lcdCtrl = 3'b000;
assign lcdPins = {lcdCtrl, lcdData};
assign lcdIn = ((write8S & mask) | ({5'b0, lcdCtrl, lcdData} & ~mask));

always @ (posedge clk) begin
    if (rst) begin
        lcdData <= 8'h00;
        lcdCtrl <= 3'b000;
    end else if (we && isLCD) begin
        {lcdCtrl, lcdData} <= lcdIn[10:0];
    end
end

reg[15:0] keyboardAddrHigh = 16'h0000;
reg[15:0] keyboardAddrLow = 16'h0000;
reg enKeyboard = 1;
assign keyboardAddr = {keyboardAddrHigh, keyboardAddrLow};
assign keyboardEn = enKeyboard;

reg[15:0] irAddrHigh = 16'h0000;
reg[15:0] irAddrLow = 16'h0000;
reg enIR = 1;
assign irAddr = {irAddrHigh, irAddrLow};
assign irEn = enIR;

wire[15:0] intEnWrite = (write8S & mask) | ({7'b0, enKeyboard, 7'b0,  enIR} & ~mask);

always @ (posedge clk) begin
    if (rst) begin
        keyboardAddrHigh <= 16'h0000;
        keyboardAddrLow <= 16'h0000;
        enKeyboard <= 1'b0;
        irAddrHigh <= 16'h0000;
        irAddrLow <= 16'h0000;
        enIR <= 1'b0;
    end else if (we) begin
        if (addr[31:1] == 31'h7FFFFFFB) begin // FFFFFFF6/7
            enIR <= |(intEnWrite[7:0]);
            enKeyboard <= |(intEnWrite[15:8]);
        end else if (addr[31:1] == 31'h7FFFFFFC) // FFFFFFF8/9
            irAddrLow <= (write8S & mask) | (irAddrLow & ~mask);
        else if (addr[31:1] == 31'h7FFFFFFD) // FFFFFFFA/B
            irAddrHigh <= (write8S & mask) | (irAddrHigh & ~mask);
        else if (addr[31:1] == 31'h7FFFFFFE) // FFFFFFFC/D
            keyboardAddrLow <= (write8S & mask) | (keyboardAddrLow & ~mask);
        else if (addr[31:1] == 31'h7FFFFFFF) // FFFFFFFE/F
            keyboardAddrHigh <= (write8S & mask) | (keyboardAddrHigh & ~mask);
    end
end

reg[15:0] breakPoint0High, breakPoint0Low;
reg[15:0] breakPoint1High, breakPoint1Low;
reg[15:0] breakPoint2High, breakPoint2Low;
reg[15:0] breakPoint3High, breakPoint3Low;
reg[15:0] breakPointAddrHigh, breakPointAddrLow;
reg[3:0] enBreakPoints;

assign bp0Addr = {breakPoint0High, breakPoint0Low};
assign bp1Addr = {breakPoint1High, breakPoint1Low};
assign bp2Addr = {breakPoint2High, breakPoint2Low};
assign bp3Addr = {breakPoint3High, breakPoint3Low};
assign bpAddr = {breakPointAddrHigh, breakPointAddrLow};
assign bp0En = enBreakPoints[0];
assign bp1En = enBreakPoints[1];
assign bp2En = enBreakPoints[2];
assign bp3En = enBreakPoints[3];

wire[15:0] bpEnIn = ((write8S & mask) | ({12'b0, enBreakPoints} & ~mask));

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
        enBreakPoints <= 4'b0000;
    end
    else if (we) begin
        if (addr[31:1] == 31'h7FFFF800) // FFFFF000/1
            enBreakPoints <= bpEnIn[3:0];
        else if (addr[31:1] == 31'h7FFFF801) // FFFFF002/3
            breakPoint0Low <= (write8S & mask) | (breakPoint0Low & ~mask);
        else if (addr[31:1] == 31'h7FFFF802) // FFFFF004/5
            breakPoint0High <= (write8S & mask) | (breakPoint0High & ~mask);
        else if (addr[31:1] == 31'h7FFFF803) // FFFFF006/7
            breakPoint1Low <= (write8S & mask) | (breakPoint1Low & ~mask);
        else if (addr[31:1] == 31'h7FFFF804) // FFFFF008/9
            breakPoint1High <= (write8S & mask) | (breakPoint1High & ~mask);
        else if (addr[31:1] == 31'h7FFFF805) // FFFFF00A/B
            breakPoint2Low <= (write8S & mask) | (breakPoint2Low & ~mask);
        else if (addr[31:1] == 31'h7FFFF806) // FFFFF00C/D
            breakPoint2High <= (write8S & mask) | (breakPoint2High & ~mask);
        else if (addr[31:1] == 31'h7FFFF807) // FFFFF00E/F
            breakPoint3Low <= (write8S & mask) | (breakPoint3Low & ~mask);
        else if (addr[31:1] == 31'h7FFFF808) // FFFFF010/1
            breakPoint3High <= (write8S & mask) | (breakPoint3High & ~mask);
        else if (addr[31:1] == 31'h7FFFF809) // FFFFF012/3
            breakPointAddrLow <= (write8S & mask) | (breakPointAddrLow & ~mask);
        else if (addr[31:1] == 31'h7FFFF80A) // FFFFF014/5
            breakPointAddrHigh <= (write8S & mask) | (breakPointAddrHigh & ~mask);
    end
end

reg[15:0] fastMem [0:14];
assign page = fastMem[0];
integer i;

always @ (posedge clk) begin
    if (rst) begin
        for (i = 0; i <= 14; i = i + 1)
            fastMem[i] <= 16'b0;
    end else if (we && isFastMem)
        fastMem[addr[4:1]] <= (write8S & mask) | (fastMem[addr[4:1]] & ~mask);;
end

wire[15:0] readNoSwap = isStack? ram1Out :
                        isHeap? ram2Out :
                        isInstr? romOut :
                        isSwitch? switch :
                        isFastMem? fastMem[addr[3:0]] :
                        16'h0000;
assign read = addr[0]? {readNoSwap[7:0], readNoSwap[15:8]} : readNoSwap;

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
