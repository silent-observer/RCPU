`ifdef __ICARUS__
`include "../source/register.v"
`include "../source/alu.v"
`include "../source/cpuController.v"
`endif

module rcpu ( // RCPU
    input wire rst, // Reset
    input wire clk, // Clock
    output reg[N-1:0] memAddr, // Memory address
    input wire [M-1:0] memRead, // Readed from memory
    output wire[M-1:0] memWrite, // For writing to memory
    output wire memRE, // Enable reading from memory
    output wire memWE); // Enable writing to memory

`include "../source/constants"

parameter M = 16; // Data bus width
parameter N = 32; // Address bus width

assign memWrite = writeDataSource? res: aluY;

wire[M-1:0] A; // A register
wire[M-1:0] B; // B register
wire[M-1:0] C; // C register
wire[N-1:0] PC; // Program counter
wire[N-1:0] SP; // Stack pointer
wire enA; // Enable write to A
wire enB; // Enable write to B
wire enC; // Enable write to C
wire[M-1:0] inR = aluY; // Input to ABC registers
wire[N-1:0] inPC = {aluYHigh, aluY}; // Input to program counter
wire enPC; // Enable write to program counter
wire enSP; // Enable write to stack pointer

wire[M-1:0] opcode; // Output of instruction register
wire enIR; // Enable write to instruction register
wire[M-1:0] value1; // Output of internal value register
wire enV1; // Enable write to internal value register
wire[M-1:0] value2; // Output of internal value register
wire enV2; // Enable write to internal value register
wire[M-1:0] res; // Output of internal value register
wire enR; // Enable write to internal value register

wire[3:0] F; // Output of flag register
wire enF; // Enable write to flag register
wire[3:0] inF; // Input to flag register

wire c = F[3]; // Carry flag
wire n = F[2]; // Negative flag
wire z = F[1]; // Zero flag
wire v = F[0]; // Overflow flag

wire[M-1:0] aluY; // ALU output Y
wire[M-1:0] aluYHigh; // ALU output Y high bits

wire sourceF;
wire[3:0] altF;
wire initSP;

register #(M) rIR (clk, memRead, opcode, enIR, rst); // Instruction register
register #(M) rV1 (clk, memRead, value1, enV1, rst); // Internal value register
register #(M) rV2 (clk, memRead, value2, enV2, rst); // Internal value register
register #(M) rR (clk, aluY, res, enR, rst); // Internal value register

register #(M) rA  (clk, inR,  A,  enA,  rst); // A register
register #(M) rB  (clk, inR,  B,  enB,  rst); // B register
register #(M) rC  (clk, inR,  C,  enC,  rst); // C register
register #(N) rPC (clk, inPC, PC, enPC, rst); // Program counter
register #(N) rSP (clk, initSP? 32'h0000D000 : {aluYHigh, aluY}, SP, enSP, rst);
register #(4) rF  (clk, sourceF? altF: inF,  F,  enF,  rst); // Flag register

reg[M-1:0] aluA; // ALU input A
reg[M-1:0] aluAHigh; // ALU input A high bits
reg[M-1:0] aluB; // ALU input B

wire[3:0] aluFunc; // ALU function control bus
wire[M-1:0] aluOutA; // ALU output to A register

wire[3:0] aluASource; // Source of ALU input A
wire[2:0] aluBSource; // Source of ALU input B

reg use32bit;

alu alu1 ( // ALU
    .a (aluA), // ALU input A
    .ahigh (aluAHigh), // ALU input A high bits
    .b (aluB), // ALU input B
    .y (aluY), // ALU output Y
    .yhigh (aluYHigh),
    .func (aluFunc), // ALU control bus
    .use32bit (use32bit),

    .co (inF[3]), // Carry flag out
    .negative (inF[2]), // Negative flag
    .zero (inF[1]), // Zero flag
    .overflow (inF[0]), // Overflow flag

    .ci (c), // Carry flag in
    .outToA (aluOutA) // ALU output to A register
    );

wire[1:0] memAddrSource;
wire writeDataSource;

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
    .saveMem1 (enV1), // Out: Enable write to internal value register
    .saveMem2 (enV2), // Out: Enable write to internal value register
    .memAddr (memAddrSource), // Out: Source of memory read/write address
    .we (memWE), // Out: Enable write to memory
    .re (memRE), // Out: Enable read from memory
    .writeDataSource (writeDataSource), // Out: Source of memory write Data
    .saveResult (enR), // Out: Enable write to ALU result register
    .enF (enF), // Out: Enable write to flag register
    .flags (F), // In: Flag register
    .sourceF (sourceF), // Out: Source of input to flag register
    .inF (altF), // Out: Alternative input to flag register
    .enSP (enSP),
    .initSP (initSP)
    );

always @ ( * ) begin // ALU input A logic
    aluA = 0; // If none, equals 0
    use32bit = 0;
    aluAHigh = 0;
    case (aluASource)
        ALU1_FROM_0: aluA = 0;
        ALU1_FROM_A: aluA = A;
        ALU1_FROM_B: aluA = B;
        ALU1_FROM_C: aluA = C;
        ALU1_FROM_PC: begin {aluAHigh, aluA} = PC; use32bit = 1; end
        ALU1_FROM_MEM: aluA = value1;
        ALU1_FROM_HIMEM: begin {aluAHigh, aluA} = {value2, value1};
            use32bit = 1;
        end
        ALU1_FROM_SP: begin {aluAHigh, aluA} = SP; use32bit = 1; end
        ALU1_FROM_XX: aluA = opcode[6:0];
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

always @ ( * ) begin
    memAddr = PC;
    case (memAddrSource)
        READ_FROM_PC: memAddr = PC;
        READ_FROM_A: memAddr = A;
        READ_FROM_ALU: memAddr = {aluYHigh, aluY};
        READ_FROM_SP: memAddr = SP;
    endcase
end

endmodule
