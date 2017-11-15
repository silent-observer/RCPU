module InterruptController (
    input wire rst,
    input wire clk,
    input wire fastClk,
    output reg irq,
    input wire turnOffIRQ,
    output reg[31:0] intAddr,
    output reg[15:0] intData,

    inout wire ps2CLK,
    inout wire ps2DATA,
    input wire[31:0] addr,
    input wire re,
    input wire we,
    input wire[31:0] bp0Addr, bp1Addr, bp2Addr, bp3Addr, bpAddr, keyboardAddr,
    input wire bp0En, bp1En, bp2En, bp3En, keyboardEn
    );

wire[8:0] pressedKey;
wire pressed;
KeyboardReader reader (
        .rst (rst),
        .clk (fastClk),
        .ps2CLK (ps2CLK),
        .ps2DATA (ps2DATA),
        .pressedKey (pressedKey),
        .pressed (pressed)
        );

wire isBP0 = (addr == bp0Addr) & bp0En & (re | we);
wire isBP1 = (addr == bp1Addr) & bp1En & (re | we);
wire isBP2 = (addr == bp2Addr) & bp2En & (re | we);
wire isBP3 = (addr == bp3Addr) & bp3En & (re | we);
reg keyPressedSync;

reg clk0, clk1, clk2;

always @(posedge fastClk) begin
    if (rst) begin
        clk0 <= 0;
        clk1 <= 0;
        clk2 <= 0;
    end
    else begin
        clk0 <= clk;
        clk1 <= clk0;
        clk2 <= clk1;
    end
end

wire posedgeClk = ~clk2 & clk1;

always @(posedge clk) begin
    
    if (rst) begin
        irq <= 0;
        intAddr <= 32'd0;
        intData <= 16'd0;
    end else if (isBP0) begin
        irq <= 1;
        intAddr <= bpAddr;
        intData <= 16'd0;
    end else if (isBP1) begin
        irq <= 1;
        intAddr <= bpAddr;
        intData <= 16'd1;
    end else if (isBP2) begin
        irq <= 1;
        intAddr <= bpAddr;
        intData <= 16'd2;
    end else if (isBP3) begin
        irq <= 1;
        intAddr <= bpAddr;
        intData <= 16'd3;
    end else if (keyPressedSync) begin
        irq <= 1;
        intAddr <= keyboardAddr;
        intData <= pressedKey;
    end else if (turnOffIRQ) begin
        irq <= 0;
    end
end

always @(posedge fastClk) begin
    if (rst) begin
        keyPressedSync <= 0;
    end else if (pressed) begin
        keyPressedSync <= 1;
    end else if (posedgeClk) begin
        keyPressedSync <= 0;
    end
end

endmodule
