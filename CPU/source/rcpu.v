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

// Registers
wire[M-1:0] A;
wire[M-1:0] B;
wire[M-1:0] C;
wire[N-1:0] PC; // Program counter
wire[N-1:0] SP; // Stack pointer
// Enable write to register
wire enA;
wire enB;
wire enC;
wire[M-1:0] inR = aluY; // Input to ABC registers
wire[N-1:0] inPC = {aluYHigh, aluY}; // Input to program counter
wire enPC; // Enable write to program counter
wire enSP; // Enable write to stack pointer

wire[M-1:0] opcode; // Instruction register
wire enIR;
wire[M-1:0] value1; // Internal registers
wire enV1;
wire[M-1:0] value2;
wire enV2;
wire[M-1:0] res;
wire enR;
// Flag register
wire[3:0] F;
wire
wire[3:0] inF;
// Flags
wire c = F[3]; // Carry
wire n = F[2]; // Negative
wire z = F[1]; // Zero
wire v = F[0]; // Overflow

wire[M-1:0] aluY; // ALU output
wire[M-1:0] aluYHigh; // ALU output high bits

wire sourceF;
wire[3:0] altF;
wire initSP;

// Registers logic
register #(M) rIR (clk, memRead, opcode, enIR, rst);
register #(M) rV1 (clk, memRead, value1, enV1, rst);
register #(M) rV2 (clk, memRead, value2, enV2, rst);
register #(M) rR (clk, aluY, res, enR, rst);

register #(M) rA  (clk, inR,  A,  enA,  rst);
register #(M) rB  (clk, inR,  B,  enB,  rst);
register #(M) rC  (clk, inR,  C,  enC,  rst);
register #(N) rPC (clk, inPC, PC, enPC, rst);
register #(N) rSP (clk, initSP? 32'h0000D000 : {aluYHigh, aluY}, SP, enSP, rst);
register #(4) rF  (clk, sourceF? altF: inF,  F,  enF,  rst);

// ALU inputs
reg[M-1:0] aluA;
reg[M-1:0] aluAHigh;
reg[M-1:0] aluB;

wire[3:0] aluFunc; // ALU function control bus
wire[M-1:0] aluOutA; // ALU output to A register

wire[3:0] aluASource; // Source of ALU input A
wire[2:0] aluBSource; // Source of ALU input B

reg use32bit; // ALU size control bit

alu alu1 ( // ALU logic
    .a (aluA),
    .ahigh (aluAHigh),
    .b (aluB),
    .y (aluY),
    .yhigh (aluYHigh),
    .func (aluFunc),
    .use32bit (use32bit),

    .co (inF[3]), // Carry flag out
    .negative (inF[2]),
    .zero (inF[1]),
    .overflow (inF[0]),

    .ci (c) // Carry flag in
    );

wire[1:0] memAddrSource;
wire writeDataSource;

cpuController cpuCTRL ( // CPU control unit (FSM)
    // Inputs
    .clk (clk),
    .rst (rst),
    .opcode (enIR? memRead : opcode), // Current instruction
    .flags (F),
    // Outputs
    .enPC (enPC),
    .aluFunc (aluFunc),
    .aluA (aluASource),
    .aluB (aluBSource),
    .enA (enA),
    .enB (enB),
    .enC (enC),
    .saveOpcode (enIR),
    .saveMem1 (enV1),
    .saveMem2 (enV2),
    .memAddr (memAddrSource), // Source of memory read/write address
    .we (memWE), // Enable write to memory
    .re (memRE), // Enable read from memory
    .writeDataSource (writeDataSource), // Source of memory write data
    .saveResult (enR), //Enable write to ALU result register
    .enF (enF),
    .sourceF (sourceF),
    .inF (altF), // Input to flag register
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

always @ ( * ) begin // Memory address logic
    memAddr = PC;
    case (memAddrSource)
        READ_FROM_PC: memAddr = PC;
        READ_FROM_A: memAddr = A;
        READ_FROM_ALU: memAddr = {aluYHigh, aluY};
        READ_FROM_SP: memAddr = SP;
    endcase
end

endmodule
