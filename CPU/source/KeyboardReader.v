module KeyboardReader (
    input wire rst,
    input wire clk,
    input wire ps2CLK,
    input wire ps2DATA,
    output reg[8:0] pressedKey,
    output wire inhibit,
    output reg pressed
    );

wire[7:0] readData;
wire update;
reg update_prev;
always @ (posedge clk)
    update_prev <= update;
wire update_posedge = !update_prev && update;


PS2Reader ps2 (
    .rst(rst),
    .clk(clk),
    .ps2CLK(ps2CLK),
    .ps2DATA(ps2DATA),
    .readData(readData),
    .update(update),
    .inhibit(inhibit)
    );

reg breakSig = 0;
reg extended = 0;

always @ (posedge clk) begin
    if (pressed)
        pressed <= 0;
    if (rst) begin
        breakSig <= 0;
        extended <= 0;
        pressed <= 0;
        pressedKey <= 9'b0;
    end else if (update_posedge) begin
        if (readData == 8'hF0) breakSig <= 1;
        else if (readData == 8'hE0) extended <= 1;
        else if (breakSig) begin
            breakSig <= 0;
            extended <= 0;
        end else begin
            pressedKey <= {extended, readData};
            pressed <= 1;
            breakSig <= 0;
            extended <= 0;
        end
    end
end

endmodule
