module TopLevel (
    input  wire clk,
    input  wire rst_in,
    input  wire[3:0] switch_in,
    output wire buzzer,
    output wire[3:0] led_out,

    inout  wire ps2CLK_in,
    input  wire ps2DATA_in,

    //output wire vgaR_out,
    //output wire vgaG_out,
    //output wire vgaB_out,
    //output wire vgaHSYNC_out,
    //output wire vgaVSYNC_out,

    output wire[3:0] tubeDig_out,
    output wire[7:0] tubeSeg_out,
	 
	 output wire[7:0] lcdData,
	 output wire lcdRS,
	 output wire lcdRW,
	 output wire lcdE
    
    //output wire uartTXD_out,
    //input  wire uartRXD_in
    );

parameter DIVISIONREGSIZE = 18;
reg[DIVISIONREGSIZE-1 : 0] adder = {DIVISIONREGSIZE{1'b0}};
always @ (posedge clk)
    adder <= adder + 18'b1;

wire[3:0] led;
wire[3:0] tubeDig;
wire[7:0] tubeSeg;
//wire[2:0] vgaRGB;
//wire vgaH;
//wire vgaV;
//wire uartTXD;


wire[3:0] switch = ~switch_in;
wire rst = ~rst_in;
wire ps2Inhibit;
reg ps2InhibitPrev = 0;
reg[10:0] inhibitCounter = 11'h7FF;
always @ (posedge clk) begin
    ps2InhibitPrev <= ps2Inhibit;
    if (ps2Inhibit && !ps2InhibitPrev) inhibitCounter <= 0;
    else if (inhibitCounter != 11'h7FF) inhibitCounter <= inhibitCounter + 1;
end

wire ps2CLK = ps2CLK_in;
wire ps2DATA = ps2DATA_in;
assign ps2CLK_in = (inhibitCounter == 11'h7FF)? 1'bz : 1'b0;
assign led_out = ~led;
assign tubeSeg_out = ~tubeSeg;
assign tubeDig_out = ~tubeDig;
assign buzzer = 0;
//assign {vgaR_out, vgaG_out, vgaB_out} = vgaRGB;
//assign vgaHSYNC_out = vgaH;
//assign vgaVSYNC_out = vgaV;
//assign uartTXD_out = uartTXD;
//wire uartRXD = uartRXD_in;
reg[1:0] dig;
always @ (posedge adder[17])
    dig <= dig + 2'b1;
	 
wire[10:0] lcdPins;
assign {lcdRS, lcdRW, lcdE, lcdData} = lcdPins;

wire bttnClk;
wire irq;

PushButton_Debouncer debouncer (clk, switch_in[3], bttnClk);

wire cpuClk = &switch[2:0] ? (switch[3]? adder[15] : adder[6]) : bttnClk;
assign led = irq;

Rintaro rintaro (clk, !cpuClk, cpuClk, rst, dig, switch[2:0], tubeDig, tubeSeg, lcdPins, ps2CLK, ps2DATA, ps2Inhibit, irq);


endmodule
