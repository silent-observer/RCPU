`include "../source/rcpu.v"
`include "../source/RAM.v"

module testRCPU;
    reg clk;
    reg rst;

    wire[15:0] addr;
    wire[15:0] read;

    RAM ram(
        .clk (clk),
        .rst (rst),
        .addr (addr),
        .rdata (read)
        );

    rcpu cpu(
        .clk (clk),
        .rst (rst),
        .memAddr (addr),
        .memRead (read)
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
        #400 $finish;
    end

endmodule
