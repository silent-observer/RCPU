`include "../source/register.v"
`include "../source/alu.v"
`include "../source/cpuController.v"

module rcpu ( // RCPU
    input wire rst, // Reset
    input wire clk, // Clock
    output reg[M-1:0] memAddr, // Memory address
    input wire [M-1:0] memRead, // Readed from memory
    output reg[M-1:0] memWrite, // For writing to memory
    output wire memWE); // Enable writing to memory

`include "../source/constants"

parameter M = 16; // Bus width

wire[M-1:0] A; // A register
wire[M-1:0] B; // B register
wire[M-1:0] C; // C register
wire[M-1:0] PC; // Program counter
wire enA; // Enable write to A
wire enB; // Enable write to B
wire enC; // Enable write to C
wire[M-1:0] inR = aluY; // Input to ABC registers
wire[M-1:0] inPC = aluY; // Input to program counter
wire enPC; // Enable write to

wire[M-1:0] opcode; // Output of instruction register
wire enIR; // Enable write to instruction register
wire[M-1:0] value; // Output of internal value register
wire enV; // Enable write to internal value register

wire[3:0] F; // Output of flag register
wire enF; // Enable write to flag register
wire[3:0] inF; // Input to flag register

wire c = F[3]; // Carry flag
wire n = F[2]; // Negative flag
wire z = F[1]; // Zero flag
wire v = F[0]; // Overflow flag

register #(M) rIR (clk, memRead, opcode, enIR, rst); // Instruction register
register #(M) rV (clk, memRead, value, enV, rst); // Internal value register

register #(M) rA  (clk, inR,  A,  enA,  rst); // A register
register #(M) rB  (clk, inR,  B,  enB,  rst); // B register
register #(M) rC  (clk, inR,  C,  enC,  rst); // C register
register #(M) rPC (clk, inPC, PC, enPC, rst); // Program counter
register #(4) rF  (clk, inF,  F,  enF,  rst); // Flag register

reg[M-1:0] aluA; // ALU input A
reg[M-1:0] aluB; // ALU input B
wire[M-1:0] aluY; // ALU output Y
wire[3:0] aluFunc; // ALU function control bus
wire[M-1:0] aluOutA; // ALU output to A register

wire[2:0] aluASource; // Source of ALU input A
wire[2:0] aluBSource; // Source of ALU input B

alu alu1 ( // ALU
    .a (aluA), // ALU input A
    .b (aluB), // ALU input B
    .y (aluY), // ALU output Y
    .func (aluFunc), // ALU control bus

    .co (inF[3]), // Carry flag out
    .negative (inF[2]), // Negative flag
    .zero (inF[1]), // Zero flag
    .overflow (inF[0]), // Overflow flag

    .ci (c), // Carry flag in
    .outToA (aluOutA) // ALU output to A register
    );

wire[1:0] memAddrSource;

cpuController cpuCTRL ( // CPU control unit (FSM)
    .clk (clk), // Clock
    .rst (rst), // Reset
    .opcode (enIR? memRead : opcode), // Current instruction
    .enPC (enPC), // Out: Enable write to program counter
    .aluFunc (aluFunc), // Out: ALU control bus
    .aluA (aluASource), // Out: Source of ALU input A
    .aluB (aluBSource), // Out: Source of ALU input B
    .enA (enA), // Out: Enable write to A register
    .enB (enB), // Out: Enable write to B register
    .enC (enC), // Out: Enable write to C register
    .saveOpcode (enIR), // Out: Enable write to instruction register
    .saveMem (enV), // Out: Enable write to internal value register
    .memAddr (memAddrSource) // Out: Source of memory read/write address
    );

always @ ( * ) begin // ALU input A logic
    aluA = 0; // If none, equals 0
    case (aluASource)
        ALU1_FROM_0: aluA = 0;
        ALU1_FROM_A: aluA = A;
        ALU1_FROM_B: aluA = B;
        ALU1_FROM_C: aluA = C;
        ALU1_FROM_PC: aluA = PC;
        ALU1_FROM_MEM: aluA = value;
    endcase
end

always @ ( * ) begin // ALU input B logic
    aluB = 0; // If none, equals 0
    case (aluBSource)
        ALU2_FROM_0: aluB = 0;
        ALU2_FROM_A: aluB = A;
        ALU2_FROM_B: aluB = B;
        ALU2_FROM_C: aluB = C;
        // From instruction itself
        ALU2_FROM_OP: aluB = {{9{opcode[7]}}, opcode[6:0]};
        // Adress from J Type instruction
        ALU2_FROM_ADDR: aluB = opcode[14:0]; // From instruction itself
        ALU2_FROM_1: aluB = 1;
    endcase
end

always @ (*) begin // Memory address logic
    memAddr = PC;
    case (memAddrSource)
        READ_FROM_PC: memAddr = PC;
        //READ_FROM_A: memAddr = A;
    endcase
end

endmodule
