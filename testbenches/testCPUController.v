`include "../source/cpuController.v"

module testCPUController;
    reg clk;
    reg rst;
    reg[15:0] opcode;

    cpuController cpuCTRL(
        .clk (clk),
        .rst (rst),
        .opcode (opcode)
        );

    initial begin
        $dumpfile ("../test.vcd");
        $dumpvars;
    end

    always #5 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        opcode = 0;
        #10 rst = 0;
        #10 opcode = 16'b0000000000100001;
        #20 $finish;
    end

endmodule
