`include "../source/rcpu.v"
`include "../source/RAM.v"

module testRCPU;
    reg clk;
    reg rst;

    wire[15:0] addr;
    wire[15:0] read;
    wire[15:0] write;
    wire we;

    RAM ram(
        .clk (clk),
        .rst (rst),
        .addr (addr),
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

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars;
    end

    always #5 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0; $readmemb("../cputest.mif", ram.memory); #9
        #800 $finish;
    end

endmodule
