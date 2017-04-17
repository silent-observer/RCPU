`timescale 10 ns / 10 ns
`ifdef __ICARUS__
`include "../source/rgpu.v"
`include "../source/RAM.v"
`endif

module testRGPU;
    reg clk;
    reg rst;

    wire[15:0] addr;
    wire[15:0] read;
    wire re;

    RAM ram(
        .clk (clk),
        .rst (rst),
        .addr (addr),
        .rdata (read),
        .wdata (16'b0),
        .we (1'b0),
        .re (re)
        );

    wire hSync, vSync;
    wire[3:0] r;
    wire[3:0] g;
    wire[3:0] b;

    rgpu gpu(
        .clk (clk),
        .rst (rst),
        .memRead (read),
        .memAddr (addr),
        .memRE (re),
        .sNT (16'h2000),
        .sNP (16'h1000),
        .sNPL (16'h0000),
        .hSync (hSync),
        .vSync (vSync),
        .r (r),
        .g (g),
        .b (b)
        );

    integer file;

    initial begin
        `ifdef VCD
            $dumpfile ("../test.vcd");
            $dumpvars;
        `else
            file = $fopen("../vga.txt");
        `endif
    end

    always @ (posedge clk) begin
        `ifndef VCD
            $fdisplay(file, "%0d ns: %01b %01b %04b %04b %04b", $time*10,
                hSync, vSync, r, g, b);
        `endif
    end

    always #2 clk = !clk;

    initial begin
        clk = 0;
        rst = 1;
        #1 rst = 0; $readmemb("../letters.mif", ram.memory); #3
        #1700000
        `ifndef VCD
            $fclose(file);
        `endif
        $finish;
    end

endmodule
