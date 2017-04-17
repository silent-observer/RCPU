`timescale 10 ns / 10 ns
`ifdef __ICARUS__
`include "../source/gpuController.v"
`endif

module testGPUController;
    reg clk;
    reg rst;

    gpuController gpuCTRL(
        .clk (clk),
        .rst (rst)
        );

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars;
    end

    always #2 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0;
        #10000000 $finish;
    end

endmodule
