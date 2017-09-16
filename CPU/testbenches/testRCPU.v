`include "../source/rcpu.v"
`include "../source/RAM2.v"

`timescale 1 us / 1 us


module testRCPU;
    reg clk;
    reg rst;

    wire[31:0] addr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;
    wire re;
    wire ready;

    RAM2 ram(
        .clk (clk),
        .rst (rst),
        .addr (addr[15:0]),
        .rdata (read),
        .wdata (write),
        .we (we),
        .re (re),
        .ready (ready)
        );

    rcpu cpu(
        .clk (!clk),
        .rst (rst),
        .memAddr (addr),
        .memRead (read),
        .memWrite (write),
        .memWE (we),
        .memRE (re),
        .memReady (ready)
        );

    integer i;

    integer clocks = 0;
    integer stalled = 0;

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars (0);
        $dumpvars (1, ram.memory[0]);
        $dumpvars (1, ram.memory[1]);
        for (i = 16'hD000; i>16'hCFE0; i = i - 1)
            $dumpvars (1, ram.memory[i]);
    end

    always #5 clk = !clk;
    always @ (posedge clk) begin
        clocks <= clocks + 1;
        if (cpu.stall)
            stalled <= stalled + 1;
    end

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0; $readmemb("../fact.rcpu", ram.memory); #9
        #10000 $finish;
    end

endmodule
