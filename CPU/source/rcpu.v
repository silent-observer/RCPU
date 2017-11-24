`ifdef __ICARUS__
`include "../source/register.v"
`include "../source/alu.v"
`include "../source/cpuController.v"
`endif

module rcpu ( // RCPU
    input wire rst, // Reset
    input wire clk, // Clock
    input wire irq, // Interrupt request
    output wire turnOffIRQ, // Interrupt acknowledgement signal
    input wire memReady, // Is memory ready
    input wire[N-1:0] intAddr, // Interrupt address
    input wire[M-1:0] intData, // Interrupt data
    input wire[M-1:0] page, // High 16 bits for addressed mode
    output reg[N-1:0] memAddr, // Memory address
    input wire[M-1:0] memRead, // Readed from memory
    output reg[M-1:0] memWrite, // For writing to memory
    output wire memRE, // Enable reading from memory
    output wire memWE, // Enable writing to memory
    // For debugging only
    output wire[M-1:0] A,
    output wire[M-1:0] B,
    output wire[M-1:0] C,
    output wire[N-1:0] PC,
    output wire[M-1:0] FP,
    output wire[M-1:0] SP,
    output wire[5:0] state,
    output wire[3:0] F
    ); 

`include "constants"

parameter M = 16; // Data bus width
parameter N = 32; // Address bus width

wire stall = !memReady && memRE;
// Registers
//wire[M-1:0] A;
//wire[M-1:0] B;
//wire[M-1:0] C;
//wire[N-1:0] PC; // Program counter
//wire[M-1:0] SP; // Stack pointer
//wire[M-1:0] FP; // Frame pointer
// Enable write signals
wire enA;
wire enB;
wire enC;
wire enPC;
wire enSP;
wire enFP;

wire[1:0] sourcePC;
wire sourceFP;

wire[M-1:0] inR = aluY; // Input to ABC registers
reg[N-1:0] inPC; // Input to program counter
always @ ( * ) begin
    inPC = {aluYHigh, aluY};
    if (sourcePC == 2'b01)
        inPC = {PC[31:16], memRead};
    else if (sourcePC == 2'b10)
        inPC = {memRead, PC[15:0]};
end


wire[M-1:0] opcode; // Instruction register
wire enIR;
wire[M-1:0] value1; // Internal registers
wire enV1;
wire[M-1:0] value2;
wire enV2;
wire[M-1:0] res;
wire enR;
// Flag register
//wire[3:0] F;
wire enF;
wire[3:0] inFFromAlu;
reg[3:0] inF;
// Flags
wire c = F[3]; // Carry
wire n = F[2]; // Negative
wire z = F[1]; // Zero
wire v = F[0]; // Overflow

wire[M-1:0] aluY; // ALU output
wire[M-1:0] aluYHigh; // ALU output high bits

wire sourceF;
wire[3:0] altF;

wire isMul;

// Registers logic
register #(M) rIR (clk, memRead, opcode, enIR && !stall, rst);
register #(M) rV1 (clk, memRead, value1, enV1 && !stall, rst);
register #(M) rV2 (clk, memRead, value2, enV2 && !stall, rst);
register #(M) rR (clk, aluY, res, enR && !stall, rst);

register #(M) rA  (clk, isMul? yhigh : inR,  A,  enA && !stall,  rst);
register #(M) rB  (clk, inR,  B,  enB && !stall,  rst);
register #(M) rC  (clk, inR,  C,  enC && !stall,  rst);
register #(N) rPC (clk, inPC, PC, enPC && !stall, rst);
register #(M) rSP (clk, aluY, SP, enSP && !stall, rst);
register #(M) rFP (clk, sourceFP? memRead: aluY, FP, enFP && !stall, rst);
register #(4) rF  (clk, inF,  F,  enF && !stall,  rst);

// ALU inputs
reg[M-1:0] aluA;
reg[M-1:0] aluAHigh;
reg[M-1:0] aluB;

wire[3:0] aluFunc; // ALU function control bus
wire[M-1:0] aluOutA; // ALU output to A register

wire[3:0] aluASource; // Source of ALU input A
wire[3:0] aluBSource; // Source of ALU input B

reg use32bit; // ALU size control bit

alu alu1 ( // ALU logic
    .a (aluA),
    .ahigh (aluAHigh),
    .b (aluB),
    .y (aluY),
    .yhigh (aluYHigh),
    .func (aluFunc),
    .use32bit (use32bit),

    .co (inFFromAlu[3]), // Carry flag out
    .negative (inFFromAlu[2]),
    .zero (inFFromAlu[1]),
    .overflow (inFFromAlu[0]),

    .ci (c) // Carry flag in
    );

wire[2:0] memAddrSource;
wire[3:0] writeDataSource;
wire readStack;

cpuController cpuCTRL ( // CPU control unit (FSM)
    // Inputs
    .clk (clk),
    .stall(stall),
    .rst (rst),
    .opcode (enIR? memRead : opcode), // Current instruction
    .flags (F),
    .irq (irq),
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
    .sourceFP (sourceFP),
    .enFP (enFP),
    .sourcePC (sourcePC),
    .inF (altF), // Input to flag register
    .enSP (enSP),
    .state (state),
    .turnOffIRQ (turnOffIRQ),
    .readStack (readStack),
    .isMul (isMul)
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
        ALU1_FROM_SP: aluA = SP;
        ALU1_FROM_XX: aluA = opcode[6:0];
        ALU1_FROM_INTADDR: begin {aluAHigh, aluA} = intAddr; use32bit = 1; end
        ALU1_FROM_DIRECTREAD: aluA = memRead;
        default: aluA = 0;
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
        ALU2_FROM_FP: aluB = FP;
        default: aluB = 0;
    endcase
end

always @ ( * ) begin // Flag register logic
    case (sourceF)
        FLAG_FROM_ALU: inF = inFFromAlu;
        FLAG_FROM_ALU_OUT: inF = aluY[3:0];
        default: inF = inFFromAlu;
    endcase
end

always @ ( * ) begin // Memory address logic
    case (memAddrSource)
        READ_FROM_PC: memAddr = PC;
        READ_FROM_A: memAddr = {page, A};
        READ_FROM_ALU: memAddr = readStack? {16'hD000, aluY} : {aluYHigh, aluY};
        READ_FROM_SP: memAddr = {16'hD000, SP};
        READ_FROM_FASTMEM: memAddr = {25'h1FFFE20, opcode[6:0]};
        default: memAddr = PC;
    endcase
end

always @ ( * ) begin // Memory write data logic
    memWrite = aluY;
    case (writeDataSource)
        WRITE_FROM_ALU: memWrite = aluY;
        WRITE_FROM_RES: memWrite = res;
        WRITE_FROM_PC1P1: memWrite = PC[15:0] + 1;
        WRITE_FROM_PC1: memWrite = PC[15:0];
        WRITE_FROM_PC2: memWrite = PC[31:16];
        WRITE_FROM_FP: memWrite = FP;
        WRITE_FROM_A: memWrite = A;
        WRITE_FROM_B: memWrite = B;
        WRITE_FROM_C: memWrite = C;
        WRITE_FROM_INTDATA: memWrite = intData;
        WRITE_FROM_F: memWrite = F;
    endcase
end

endmodule