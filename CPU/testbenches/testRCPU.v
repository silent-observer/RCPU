`include "../source/rcpu.v"
`include "../source/RAM.v"

`timescale 1 us / 1 us


module testRCPU;
    reg clk;
    reg rst;

    wire[31:0] addr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;

    RAM ram(
        .clk (clk),
        .rst (rst),
        .addr (addr[15:0]),
        .rdata (read),
        .wdata (write),
        .we (we)
        );

    rcpu cpu(
        .clk (clk),
        .rst (rst),
        .memAddr (addr),
        .memRead (read),
        .memWrite (write),
        .memWE (we)
        );

    integer i;

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars (0, cpu);
        $dumpvars (1, ram.memory[5]);
        $dumpvars (1, ram.memory[6]);
        for (i = 16'hD000; i>16'hCFE0; i = i - 1)
            $dumpvars (1, ram.memory[i]);
    end

    always #5 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0; $readmemb("../sqrt.rcpu", ram.memory); #9
        #10000 $finish;
    end

endmodule
