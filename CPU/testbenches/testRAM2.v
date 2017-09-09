`timescale 1 us / 1 us
`include "../source/RAM2.v"

module testRAM;

reg[15:0] addr;
reg clk;
reg rst;
reg we;
reg re;
reg[15:0] wdata;

wire[15:0] rdata;
wire ready;

RAM2 mem (
    .rst (rst),
    .clk (clk),
    .we  (we),
    .re  (re),
    .addr (addr),
    .wdata (wdata),
    .rdata (rdata),
    .ready (ready)
    );

always
    #5 clk = !clk;

initial begin
    $dumpfile ("../test.vcd");
    $dumpvars;
end

initial begin
    $display ("\t\ttime,\tclk,\taddr,\twdata,\trdata,\twe");
    $monitor (  "%d,\t%b,\t%4h,\t%2h,\t%2h,\t%b",
                $time, clk, addr, wdata, rdata, we);
end

initial begin
    rst = 1;
    clk = 0;
    we = 0;
    re = 0;
    addr = 16'h0000;
    wdata = 16'h0000;
    #10 rst = 0; re = 1;
    #20 wdata = 16'h1212; we = 1; re = 0;
    #10 we = 0;
    #10 addr = 16'h0001; re = 1;
    #20 wdata = 16'h3434; we = 1; re = 0;
    #10 we = 0;
    #10 addr = 16'hABCD; re = 1;
    #20 wdata = 16'h5656; we = 1; re = 0;
    #10 we = 0;
    #10 addr = 16'h0000; re = 1;
    #20 addr = 16'h0001; re = 1;
    #20 addr = 16'hABCD; re = 1;
    #20 re = 0;
    #10 rst = 1;
    #10 $finish;
end

endmodule
