`include "../source/register.v"

module testRegister;

reg clk;
reg rst;
reg en;
reg[15:0] in;

wire[15:0] out;

register reg1 (
    .clk (clk),
    .en  (en),
    .in (in),
    .out (out),
    .rst (rst)
    );

always
    #5 clk = !clk;

initial begin
    $dumpfile ("../test.vcd");
    $dumpvars;
end

initial begin
    rst = 0;
    clk = 0;
    en = 0;
    in = 16'h0000;

    #10 rst = 1;
    #10 rst = 0;
    #10 in = 16'h1234;
    #10 en = 1;
    #10 en = 0;
    #20 in = 16'h5678;
    #10 en = 1;
    #20 in = 16'h9ABC;
    #10 in = 16'hDEF0;
    #10 en = 0;
    #10 rst = 1;

    #20 $finish;
end

endmodule
