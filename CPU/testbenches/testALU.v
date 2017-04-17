`ifndef MODEL_TECH
`include "../source/alu.v"
`endif

module testALU;

task assert;
input cond;
begin
    if (!cond) begin
        $display("Error!");
        $finish;
    end
end;
endtask

reg[15:0] a;
reg[15:0] b;
reg[3:0] func;
reg ci;

wire[3:0] flags;
wire[15:0] y;
wire[15:0] toA;

alu alu1 (
    .a (a),
    .b (b),
    .func (func),
    .ci (ci),
    .y (y),
    .co (flags[3]),
    .negative (flags[2]),
    .zero (flags[1]),
    .overflow (flags[0]),
    .outToA (toA)
    );

initial begin
    $dumpfile ("../test.vcd");
    $dumpvars;
end

/*initial begin
    $display ("\t\ttime,\ta,\tb,\tfunc,\tata,\twe");
    $monitor (  "%d,\t%b,\t%4h,\t%2h,\t%2h,\t%b",
                $time, clk, addr, wdata, rdata, we);
end*/

initial begin
    a = 0;
    b = 0;
    func = 4'b0000; // ADD
    ci = 0;
    #9 assert (y === 0 && flags === 4'b0010); #1
    a = 15;
    b = 25;
    #9 assert (y === 40 && flags === 4'b0000); #1
    a = -10;
    b = 70;
    #9 assert (y === 60 && flags === 4'b1000); #1
    a = 16'h4000;
    b = 16'h4000;
    #9 assert (y === 16'h8000 && flags === 4'b0101); #1
    a = 16'h8000;
    b = 16'h8000;
    #9 assert (y === 0 && flags === 4'b1011); #1
    a = -1;
    b = 1;
    #9 assert (y === 0 && flags === 4'b1010); #1
    func = 4'b0001;  // ADC
    a = -10;
    b = 70;
    #9 assert (y === 60 && flags === 4'b1000); #1
    ci = 1;
    #9 assert (y === 61 && flags === 4'b1000); #1
    func = 4'b0010; // SUB
    #9 assert (y === -16'd80 && flags === 4'b0100); #1
    func = 4'b0011; // SBC
    #9 assert (y === -16'd81 && flags === 4'b0100); #1
    ci = 0;
    func = 4'b0100; // MUL
    a = 7; b = 6;
    #9 assert (y === 42 && flags === 4'b0000); #1
    a = 7; b = -6;
    #9 assert (y === -16'd42 && flags === 4'b0100); #1
    a = -7; b = -6;
    #9 assert (y === 42 && flags === 4'b0000); #1
    a = 256; b = 256;
    #9 assert (y === 0 && toA === 1 && flags === 4'b0000); #1

    func = 4'b0101; //MLL
    a = 7; b = 6;
    #9 assert (y === 42 && flags === 4'b0000); #1
    a = 7; b = -6;
    #9 assert (y === -16'd42 && flags === 4'b0100); #1
    a = -7; b = -6;
    #9 assert (y === 42 && flags === 4'b0000); #1

    func = 4'b0111; //RAS
    a = 15; b = 2;
    #9 assert (y === 3 && flags === 4'b1000); #1
    a = -15; b = 2;
    #9 assert (y === -16'd4 && flags === 4'b0100); #1

    func = 4'b1000; //LSH
    a = 16'b100101; b = 1;
    #9 assert (y === 16'b1001010 && flags === 4'b0000); #1
    b = 2;
    #9 assert (y === 16'b10010100 && flags === 4'b0000); #1
    a = 2; b = 15;
    #9 assert (y === 0); #1

    func = 4'b1001; //RSH
    a = 16'b100101; b = 1;
    #9 assert (y === 16'b10010 && flags === 4'b1000); #1
    b = 2;
    #9 assert (y === 16'b1001 && flags === 4'b0000); #1

    func = 4'b1010; //LRT
    a = 16'b1000000000001010; b = 1;
    #9 assert (y === 16'b10101 && flags === 4'b0000); #1
    b = 2;
    #9 assert (y === 16'b101010 && flags === 4'b0000); #1

    func = 4'b1011; //RRT
    b = 1;
    #9 assert (y === 16'b0100000000000101 && flags === 4'b0000); #1
    b = 2;
    #9 assert (y === 16'b1010000000000010 && flags === 4'b0100); #1

    func = 4'b1100; //AND
    a = 16'b0011001100110011;
    b = 16'b0101010101010101;
    #9 assert (y === 16'b0001000100010001 && flags === 4'b0000); #1
    func = 4'b1101; //OR
    #9 assert (y === 16'b0111011101110111 && flags === 4'b0000); #1
    func = 4'b1110; //XOR
    #9 assert (y === 16'b0110011001100110 && flags === 4'b0000); #1
    func = 4'b1111; //NOT
    #9 assert (y === 16'b1100110011001100 && flags === 4'b0100); #1



    $finish;
end

endmodule
