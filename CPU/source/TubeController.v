module TubeROM (
    input wire[3:0] value,
    input wire auxValue,
    output reg[6:0] segments
    );

always @ (*) begin
    if (auxValue) begin
        case (value)
            4'h0: segments = 7'h00; // Empty
            4'h1: segments = 7'h73; // P
            4'h2: segments = 7'h78; // T
            4'h3: segments = 7'h50; // R
            4'h4: segments = 7'h1C; // V
            4'h5: segments = 7'h76; // H
            4'h6: segments = 7'h38; // L
            default: segments = 7'b0;
        endcase
    end
    else begin 
        case (value)
            4'h0: segments = 7'h3F; // 0
            4'h1: segments = 7'h06; // 1
            4'h2: segments = 7'h5B; // 2
            4'h3: segments = 7'h4F; // 3
            4'h4: segments = 7'h66; // 4
            4'h5: segments = 7'h6D; // 5
            4'h6: segments = 7'h7D; // 6
            4'h7: segments = 7'h07; // 7
            4'h8: segments = 7'h7F; // 8
            4'h9: segments = 7'h6F; // 9
            4'hA: segments = 7'h77; // A
            4'hB: segments = 7'h7C; // B
            4'hC: segments = 7'h39; // C
            4'hD: segments = 7'h5E; // D
            4'hE: segments = 7'h79; // E
            4'hF: segments = 7'h71; // F
            default: segments = 7'b0;
        endcase
    end
end
endmodule

module TubeController (
    input wire[1:0] dig,
    input wire[3:0] dig1,
    input wire[3:0] dig2,
    input wire[3:0] dig3,
    input wire[3:0] dig4,
    input wire[3:0] dots,
    input wire[3:0] auxs,
    output wire[3:0] tubeDig,
    output wire[7:0] tubeSeg
    );

wire[3:0] value = (dig == 2'd0)? dig1 :
                        (dig == 2'd1)? dig2 :
                        (dig == 2'd2)? dig3 :
                        dig4;

TubeROM rom (value, auxs[dig], tubeSeg[6:0]);

assign tubeSeg[7] = dots[dig];
assign tubeDig = (dig == 2'd0)? 4'b0001 :
                      (dig == 2'd1)? 4'b0010 :
                      (dig == 2'd2)? 4'b0100 :
                      4'b1000;
endmodule
