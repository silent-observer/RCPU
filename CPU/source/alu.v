module alu(
    input wire[N-1:0] a,
    input wire[N-1:0] ahigh,
    input wire[N-1:0] b,
    input wire[3:0] func,
    input wire ci,
    input wire use32bit,
    output reg[N-1:0] y,
    output reg[N-1:0] yhigh,
    output reg co,
    output reg zero,
    output reg overflow,
    output reg negative );

parameter N = 16;



reg[2*N-1:0] negatedB;
reg[N:0] negatedCI;

reg[N-1:0] rshift;
reg[N-1:0] rrotate;
reg[N-1:0] lrotate;
reg[N-1:0] lshift;

wire[2*N-1:0] mul = {{N{a[N-1]}}, a} * {{N{b[N-1]}}, b};

reg invCO;
reg signed[N:0] sigA;

always @ (a, b, ci, func) begin
    y = 0;
    yhigh = 0;
    co  = 0;
    overflow = 0;

    negatedB = func[1] ? -b : b;
    negatedCI = func[1] ? -ci : ci;
    sigA = {a, 1'b0};
    {rshift, rrotate} = {a, a} >> b[3:0];
    {lrotate, lshift} = ({a, a} << b[3:0]);

    casez (func)
        4'b00zz: begin
            if (use32bit)
                {invCO, yhigh, y} = {ahigh, a} + negatedB +
                    (func[0] ? negatedCI : 16'b0);
            else
                {invCO, y} = a + negatedB + (func[0] ? negatedCI : 16'b0);
            overflow = (a[N-1] == negatedB[N-1]) & (y[N-1] != a[N-1]);
            co = func[1] ^ invCO;
        end
        4'b01zz: begin
            if (func[1] == 1'b0) begin
                {yhigh, y} = {{N{a[N-1]}}, a} * {{N{b[N-1]}}, b};
                overflow = (yhigh != 0 && yhigh != 16'hFFFF) && func[0];
            end else if (func[1:0] == 2'b11) begin
                {y, co} = sigA >>> b[3:0];
            end
            else if (func[1:0] == 2'b10) begin
                {yhigh ,y} = {ahigh, a[15], b[14:0]};
            end
        end
        4'b1000: {co, y} = {lrotate[0], lshift};
        4'b1001: {co, y} = {rrotate[N-1], rshift};
        4'b1010: y = lrotate;
        4'b1011: y = rrotate;
        4'b1100: y = a & b;
        4'b1101: y = a | b;
        4'b1110: y = a ^ b;
        4'b1111: y = ~a;
    endcase

    zero = y == 0 && yhigh == 0;
    negative = yhigh == 0? y[N-1] : yhigh[N-1];
end

endmodule
