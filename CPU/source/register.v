module register( // Register
    input wire clk, // Clock
    input wire[N-1:0] in, // Data to write
    output reg[N-1:0] out, // Data from register
    input wire en, // Write enable
    input wire rst); // Reset

parameter N = 16; // Width

always @ (posedge clk or posedge rst)
    if (rst) // Set to 0 at reset
        out <= 0;
    else if (en) // Write to register
        out <= in;

endmodule
