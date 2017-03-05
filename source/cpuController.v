module  cpuController( // CPU control unit (FMA)
    input wire clk, // Clock
    input wire rst, // Reset
    input wire[15:0] opcode, // Current instruction

    output reg[1:0] memAddr, // Source of memory address
    output reg enPC, // Enable write to program counter
    output reg saveOpcode, // Enable write to instruction register
    output reg saveMem, // Enable write to internal value register
    output reg[3:0] aluFunc, // ALU control bus
    output reg[2:0] aluA, // Source of ALU input A
    output reg[2:0] aluB, // Source of ALU input B
    output reg enA, // Enable write to A register
    output reg enB, // Enable write to B register
    output reg enC  // Enable write to C register
    );

`include "../source/constants"

parameter [4:0] FETCH = 5'b00000; // Instruction fetching cycle
parameter [4:0] ATYPE = 5'b00001; // Execution of A Type instructions
parameter [4:0] ITYPE = 5'b00010; // Execution of I Type instructions
parameter [4:0] HALT = 5'b11111; // CPU stop

parameter [4:0] RIMMED = 5'b10000; // Read immediate value
parameter [4:0] RADDRESS = 5'b10001; // Read adressed value


reg[4:0] state; // Current FSM state
reg[4:0] nextState; // Next FSM state

reg[4:0] returnState; // State to which FSM will return after reading value

wire[2:0] s1 = opcode[11:9]; // Source 1 field of opcode (common for all)

always @ (posedge clk or posedge rst) begin // FMS sequential logic
    if (rst) begin // Reset of all state registes
        state <= FETCH;
        returnState <= FETCH;
    end else begin
        state <= nextState; // Go to next state
    end
end

always @ (*) begin
    nextState = HALT; // If invalid state, then stop CPU
    case (state)
        FETCH: begin
            if (s1[2] == 1'b0) // If read addressing mode == register
                nextState = returnState; // To main state of instruction type
            else if (s1 == 3'b100) // If read addressing mode == immediate
                nextState = RIMMED;
            else if (s1 == 3'b110) // If read addressing mode == immediate
                nextState = RADDRESS;
        end
        ATYPE: nextState = FETCH; // Fetch next instruction
        ITYPE: nextState = FETCH; // Fetch next instruction
        RIMMED: nextState = returnState; // To main state of instruction type
        RADDRESS: nextState = returnState; // To main state of instruction type
    endcase

    returnState = HALT; // If invalid instruction, then stop CPU

    if (opcode[15:12] == 4'b0000) // A Type
        returnState = ATYPE;
    else if (opcode[15:14] == 2'b01) // I Type
        returnState = ITYPE;
end

always @ (*) begin
    memAddr = 0; // If not important, set everything to 0
    enPC = 0;
    saveOpcode = 0;
    aluFunc = 0;
    aluA = 0;
    aluB = 0;
    enA = 0;
    enB = 0;
    enC = 0;
    saveMem = 0;
    case (state)
        FETCH: begin
            memAddr = READ_FROM_PC; // Fetch instruction
            saveOpcode = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        ATYPE: begin

            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = opcode[4:3]; // Source for ALU input B
            aluFunc = opcode[8:5]; // ALU control is in the instruction
            case (opcode[1:0]) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
            endcase
        end

        ITYPE: begin
            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            // ALU control is in pattern 3312 if opcode - 12|3
            aluFunc = {opcode[8], opcode[8], opcode[13:12]};
            aluB = ALU2_FROM_OP; // Source for ALU input B
            case (s1) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
            endcase
        end

        RIMMED: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value from (PC)
            saveMem = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        RADDRESS: begin // Read immediate value
            memAddr = READ_FROM_A; // Read value from (A)
            saveMem = 1;
        end
    endcase
end
endmodule
