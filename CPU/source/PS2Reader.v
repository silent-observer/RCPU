module PS2Reader (
    input wire rst,
    input wire clk,
    input wire ps2CLK,
    input wire ps2DATA,
    output reg[7:0] readData,
    output reg update,
    output reg[2:0] err,
	output reg inhibit
    );

reg[3:0] state = 0;

reg earlyRead = 0;

wire parity = ~^ readData;

/*reg ps2CLK_prev = 1;
always @ (posedge clk)
    ps2CLK_prev <= ps2CLK;
wire ps2CLK_negedge = ps2CLK_prev && !ps2CLK;*/

always @ (negedge ps2CLK or posedge rst) begin
    if (rst) begin
        state <= 0;
        update <= 0;
        err <= 3'b0;
		readData <= 0;
		inhibit = 0;
		earlyRead = 0;
    end else begin
        inhibit = 0;
        case (state)
            4'd0: if (ps2DATA != 1'b0) begin
                    if (!earlyRead) earlyRead = 1;
                    else inhibit = 1;
                end else earlyRead = 0;
            4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8:
                readData[state-1] <= ps2DATA;
            4'd9: begin
                if (ps2DATA != parity) inhibit = 1;
                else update <= 1;
            end
            4'd10: begin
                if (ps2DATA != 1'b1) inhibit = 1;
                update <= 0;
            end
            default: begin end
        endcase

        if (state != 4'd10 && !earlyRead && !inhibit) state <= state + 5'd1;
        else state <= 4'd0;
    end
end

endmodule // PS2Reader
