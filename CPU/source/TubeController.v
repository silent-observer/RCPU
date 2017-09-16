module TubeROM (
	input wire[3:0] value,
	output reg[6:0] segments
	);

always @ (*) begin
	segments = 7'b0;
	case (value)
		4'h0: segments = 7'h3F;
		4'h1: segments = 7'h06;
		4'h2: segments = 7'h5B;
		4'h3: segments = 7'h4F;
		4'h4: segments = 7'h66;
		4'h5: segments = 7'h6D;
		4'h6: segments = 7'h7D;
		4'h7: segments = 7'h07;
		4'h8: segments = 7'h7F;
		4'h9: segments = 7'h6F;
		4'hA: segments = 7'h77;
		4'hB: segments = 7'h7C;
		4'hC: segments = 7'h39;
		4'hD: segments = 7'h5E;
		4'hE: segments = 7'h79;
		4'hF: segments = 7'h71;
	endcase
end
endmodule

module TubeController (
    input wire[1:0] dig,
    input wire[3:0] dig1,
    input wire[3:0] dig2,
    input wire[3:0] dig3,
    input wire[3:0] dig4,
    input wire[3:0] dots,
    output wire[3:0] tubeDig,
    output wire[7:0] tubeSeg
    );

wire[3:0] value = (dig == 2'd0)? dig1 :
						(dig == 2'd1)? dig2 :
						(dig == 2'd2)? dig3 :
						dig4;

TubeROM rom (value, tubeSeg[6:0]);

assign tubeSeg[7] = dots[dig];
assign tubeDig = (dig == 2'd0)? 4'b0001 :
					  (dig == 2'd1)? 4'b0010 :
					  (dig == 2'd2)? 4'b0100 :
					  4'b1000;
endmodule
