module Rintaro (
    input wire clk1,
    input wire clk2,
    input wire rst,
    input wire[1:0] dig,
    input wire[2:0] switch,
    output wire[3:0] tubeDig,
    output wire[7:0] tubeSeg,
    output wire[10:0] lcdPins
    );
    
    wire[31:0] addr, intAddr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;
    wire re;
    wire ready;
    wire irq = 0;
     
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
        .intAddr (intAddr)
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
        .irq (irq),
        .intAddr (intAddr),
          
        .PC (PC),
        .FP (FP),
        .A (A),
        .B (B),
        .C (C),
        .state (state)
        );
     
    reg[15:0] value;
    always @ (*) begin
        case (switch)
            3'd0: value = PC[15:0];
            3'd1: value = A;
            3'd2: value = B;
            3'd3: value = C;
            3'd4: value = addr[15:0];
            3'd5: value = re? read : we? write : read;
            3'd6: value = {3'b000, re, 3'b000, we, 2'b00, state};
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