`ifndef MODEL_TECH
`include "../source/rcpu.v"
`include "../source/RAM.v"
`endif

module testRCPU;
    reg clk;
    reg rst;

    wire[15:0] addr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;
    wire re;

    RAM ram(
        .clk (clk),
        .rst (rst),
        .addr (addr),
        .rdata (read),
        .wdata (write),
        .we (we),
        .re (re)
        );

    rcpu cpu(
        .clk (clk),
        .rst (rst),
        .memAddr (addr),
        .memRead (read),
        .memWrite (write),
        .memWE (we),
        .memRE (re)
        );

    integer i;

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars (0, cpu);
        $dumpvars (1, ram.memory[0]);
        for (i = 16'hD000; i<16'hD100; i = i + 1)
            $dumpvars (1, ram.memory[i]);
    end

    always #5 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0; $readmemb("../a.rcpu", ram.memory); #9
        #10000 $finish;
    end

endmodule
