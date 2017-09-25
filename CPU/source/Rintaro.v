module Rintaro (
    input wire fastClk,
    input wire clk1,
    input wire clk2,
    input wire rst,
    input wire[1:0] dig,
    input wire[2:0] switch,
    output wire[3:0] tubeDig,
    output wire[7:0] tubeSeg,
    output wire[10:0] lcdPins,
    inout wire ps2CLK,
    inout wire ps2DATA,
    output wire irqOut
    );
    
    wire[31:0] addr, intAddr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;
    wire re;
    wire ready;
    reg irq = 1'b0;
    assign irqOut = irq;
    wire turnOffIRQ;
    wire intEn;
     
    wire [31:0] PC;
    wire [15:0] A, B, C, FP;
    wire [5:0] state;

    RAM ram (
        .rst (rst),
        .clk (clk1),
        .addr (addr),
        .write (write),
        .we (we),
        .read (read),
        .re (re),
        .ready (ready),
        .lcdPins (lcdPins),
        .intAddr (intAddr),
        .intEn (intEn)
        );

    rcpu cpu(
        .clk (clk2),
        .rst (rst),
        .memAddr (addr),
        .memRead (read),
        .memWrite (write),
        .memWE (we),
        .memRE (re),
        .memReady (ready),
        .irq (irq && intEn),
        .turnOffIRQ (turnOffIRQ),
        .intAddr (intAddr),
        .intData (intData),
          
        .PC (PC),
        .FP (FP),
        .A (A),
        .B (B),
        .C (C),
        .state (state)
        );

    wire[8:0] pressedKey;
    wire pressed;
    reg pressedPrev = 1'b0;
    wire pressedPosedge = pressed && !pressedPrev;

    always @(posedge fastClk) begin
        pressedPrev <= pressed;
    end

    KeyboardReader reader (
        .rst (rst),
        .clk (fastClk),
        .ps2CLK (ps2CLK),
        .ps2DATA (ps2DATA),
        .pressedKey (pressedKey),
        .pressed (pressed)
        );

    reg[15:0] value;
    reg[2:0] mode;
    reg[15:0] intData;

    always @(posedge fastClk) begin
        if (rst) begin
            mode <= 3'h0;
            intData <= 16'b0;
        end
        else if (pressedPosedge) begin
            if (switch[0]) begin
                irq <= 1;
                intData <= pressedKey;
            end else case (pressedKey)
                // 'P'
                9'h04D: mode <= 3'h0;
                // 'A'
                9'h01C: mode <= 3'h1;
                // 'B'
                9'h032: mode <= 3'h2;
                // 'C'
                9'h021: mode <= 3'h3;
                // 'R'
                9'h02D: mode <= 3'h4;
                // 'D'
                9'h023: mode <= 3'h5;
                // 'S'
                9'h01B: mode <= 3'h6;
                // 'F'
                9'h02B: mode <= 3'h7;
                // 'I'
                9'h043: irq <= 1;
                default: begin end
            endcase;
        end
        if (turnOffIRQ)
            irq <= 0;
    end
     
    
    always @ (*) begin
        case (mode)
            3'd0: value = PC[15:0];
            3'd1: value = A;
            3'd2: value = B;
            3'd3: value = C;
            3'd4: value = addr[15:0];
            3'd5: value = re? read : we? write : read;
            3'd6: value = {2'b00, irq, intEn, 2'b00, re, we, 2'b00, state};
            3'd7: value = PC[15:0];
            default: value = 16'h0000;
        endcase
    end
     
    TubeController tube (
        .dig (dig),
        .dig4 (value[15:12]),
        .dig3 (value[11:8]),
        .dig2 (value[7:4]),
        .dig1 (value[3:0]),
        .dots (4'b0000),
        .tubeDig (tubeDig),
        .tubeSeg (tubeSeg)
        );

    
endmodule 