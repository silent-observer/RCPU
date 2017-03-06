module  cpuController( // CPU control unit (FMA)
    input wire clk, // Clock
    input wire rst, // Reset
    input wire[15:0] opcode, // Current instruction
    input wire[3:0] flags, // Current flag register

    output reg[1:0] memAddr, // Source of memory address
    output reg enPC, // Enable write to program counter
    output reg saveOpcode, // Enable write to instruction register
    output reg saveMem, // Enable write to internal value register
    output reg[3:0] aluFunc, // ALU control bus
    output reg[2:0] aluA, // Source of ALU input A
    output reg[2:0] aluB, // Source of ALU input B
    output reg enA, // Enable write to A register
    output reg enB, // Enable write to B register
    output reg enC, // Enable write to C register
    output reg we, // Enable write to memory
    output reg writeDataSource, // Source of data for writing to memory
    output reg saveResult, // Enable write to internal result register
    output reg enF, // Enable write to flag register
    output reg sourceF, // Source of input to flag register
    output reg[3:0] inF, // Alternative input to flag register
    output reg enSP // Enable write to stack pointer
    );

`include "../source/constants"

parameter [4:0] FETCH = 5'b00000; // Instruction fetching cycle
parameter [4:0] ATYPE = 5'b00001; // Execution of A Type instructions
parameter [4:0] ITYPE = 5'b00010; // Execution of I Type instructions
parameter [4:0] JTYPE = 5'b00011; // Execution of J Type instructions
parameter [4:0] SITYPE = 5'b00100; // Execution of SI Type instructions
parameter [4:0] JFGINSTR = 5'b00101; // Execution of JFS/JFC instructions
parameter [4:0] FLGINSTR = 5'b00110; // Execution of FLS/FLC instructions
parameter [4:0] PUSH1 = 5'b01000; // Execution of PUSH instruction
parameter [4:0] PUSH2 = 5'b01001;
parameter [4:0] POP1 = 5'b01010; // Execution of POP instruction
parameter [4:0] POP2 = 5'b01011;
parameter [4:0] HALT = 5'b11111; // CPU stop

parameter [4:0] RIMMED = 5'b10000; // Read immediate value
parameter [4:0] RADDRESS = 5'b10001; // Read adressed value
parameter [4:0] RABSOLUTE1 = 5'b10010; // Read absolute adressed value
parameter [4:0] RABSOLUTE2 = 5'b10011;
parameter [4:0] RABSOLUTEI1 = 5'b10100; // Read absolute indexed value
parameter [4:0] RABSOLUTEI2 = 5'b10101;

parameter [4:0] WABSOLUTE1 = 5'b11010; // Write absolute adressed value
parameter [4:0] WABSOLUTEI1 = 5'b11011; // Write absolute indexed value
parameter [4:0] WABSOLUTE2 = 5'b11100; // Write absolute adressed value
parameter [4:0] WABSOLUTEI2 = 5'b11101; // Write absolute indexed value

reg[4:0] state; // Current FSM state
reg[4:0] nextState; // Next FSM state

reg[4:0] returnState; // State to which FSM will return after reading value

wire[2:0] s1 = opcode[11:9]; // Source 1 field of opcode (common for all)

always @ (posedge clk or posedge rst) begin // FMS sequential logic
    if (rst) begin // Reset of all state registes
        state <= FETCH;
    end else begin
        state <= nextState; // Go to next state
    end
end

always @ (*) begin
    nextState = HALT; // If invalid state, then stop CPU
    case (state)
        FETCH: begin
            // If read addressing mode == register
            if (s1[2] == 1'b0
                || (returnState != ATYPE &&
                    returnState != ITYPE &&
                    returnState != SITYPE &&
                    returnState != PUSH1))
                nextState = returnState; // To main state of instruction type
            else if (s1 == 3'b100) // If read addressing mode == immediate
                nextState = RIMMED;
            else if (s1 == 3'b101) // If read addressing mode == absolute
                nextState = RABSOLUTE1;
            else if (s1 == 3'b110) // If read addressing mode == address
                nextState = RADDRESS;
            // If read addressing mode == absolute indexed
            else if (s1 == 3'b111)
                nextState = RABSOLUTEI1;
        end
        JTYPE, JFGINSTR, FLGINSTR, PUSH2: nextState = FETCH;
            // Fetch next instruction
        ATYPE:
            if (opcode[2:0] == DEST_ABS) nextState = WABSOLUTE1;
            else if (opcode[2:0] == DEST_ABSI) nextState = WABSOLUTEI1;
            else nextState = FETCH;
        ITYPE:
            if (s1 == DEST_ABS) nextState = WABSOLUTE1;
            else if (s1 == DEST_ABSI) nextState = WABSOLUTEI1;
            else nextState = FETCH;
        SITYPE:
            if (opcode[7:5] == DEST_ABS) nextState = WABSOLUTE1;
            else if (opcode[7:5] == DEST_ABSI) nextState = WABSOLUTEI1;
            else nextState = FETCH;
        POP2:
            if (s1 == DEST_ABS) nextState = WABSOLUTE1;
            else if (s1 == DEST_ABSI) nextState = WABSOLUTEI1;
            else nextState = FETCH;
        // To main state of instruction type
        RIMMED, RADDRESS, RABSOLUTE2, RABSOLUTEI2: nextState = returnState;
        RABSOLUTE1: nextState = RABSOLUTE2; // To next step
        RABSOLUTEI1: nextState = RABSOLUTEI2; // To next step
        WABSOLUTE1: nextState = WABSOLUTE2; // To next step
        WABSOLUTEI1: nextState = WABSOLUTEI2; // To next step
        WABSOLUTE2, WABSOLUTEI2: nextState = FETCH;
        PUSH1: nextState = PUSH2;
        POP1: nextState = POP2;
    endcase
end

reg isFLG;

always @ ( * ) begin
    returnState = HALT; // If invalid instruction, then stop CPU
    isFLG = 0;

    if (opcode[15:12] == 4'b0000) // A Type
        returnState = ATYPE;
    else if (opcode[15:14] == 2'b01) // I Type
        returnState = ITYPE;
    else if (opcode[15] == 1'b1) // J Type
        returnState = JTYPE;
    else if (opcode[15:12] == 4'b0001) // SI Type
        returnState = SITYPE;
    else if (opcode[15:12] == 4'b0010) // F Type
        if (opcode[11]) begin // FLS/FLC
            isFLG = 1;
            returnState = FETCH;
        end else if (flags[opcode[9:8]] == opcode[10]) // If condition is true
            returnState = JFGINSTR;
        else returnState = FETCH; // If condition is false
    else if (opcode[15:12] == 4'b0011) // SP Type
        if (opcode[7]) // POP
            returnState = POP1;
        else // PUSH
            returnState = PUSH1;
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
    we = 0;
    writeDataSource = 0;
    saveResult = 0;
    enF = 0;
    sourceF = 0;
    inF = 0;
    enSP = 0;
    case (state)
        FETCH: begin
            memAddr = READ_FROM_PC; // Fetch instruction
            saveOpcode = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;

            if (isFLG) begin
                enF = 1;
                sourceF = 1;
                if (opcode[10])
                    inF = flags | 1 << opcode[9:8];
                else
                    inF = flags & ~(1 << opcode[9:8]);
            end
        end

        ATYPE: begin

            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = opcode[4:3]; // Source for ALU input B
            aluFunc = opcode[8:5]; // ALU control is in the instruction
            enF = 1; // Update flags
            case (opcode[2:0]) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
                DEST_ADR: begin
                    we = 1;
                    writeDataSource = WRITE_FROM_ALU;
                    memAddr = READ_FROM_A;
                end
                DEST_ABS, DEST_ABSI: begin
                    saveResult = 1;

                    memAddr = READ_FROM_PC; // Read value (PC)
                    saveMem = 1;
                end
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
            enF = 1; // Update flags
            case (s1) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
                DEST_ADR: begin
                    we = 1;
                    writeDataSource = WRITE_FROM_ALU;
                    memAddr = READ_FROM_A;
                end
                DEST_ABS, DEST_ABSI: begin
                    saveResult = 1;

                    memAddr = READ_FROM_PC; // Read value (PC)
                    saveMem = 1;
                end
            endcase
        end

        JTYPE: begin
            aluA = ALU1_FROM_PC; // Sign from PC
            aluB = ALU2_FROM_ADDR; // Address from instruction
            aluFunc = 4'b0110;
            enPC = 1; // Write to PC
        end

        SITYPE: begin
            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            // ALU control is in pattern 3312 if opcode - 12|3
            aluFunc = {2'b10, opcode[8:7]};
            aluB = ALU2_FROM_OP; // Source for ALU input B
            enF = 1; // Update flags
            case (s1) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
                DEST_ADR: begin
                    we = 1;
                    writeDataSource = WRITE_FROM_ALU;
                    memAddr = READ_FROM_A;
                end
                DEST_ABS, DEST_ABSI: begin
                    saveResult = 1;

                    memAddr = READ_FROM_PC; // Read value (PC)
                    saveMem = 1;
                end
            endcase
        end

        JFGINSTR: begin
            aluA = ALU1_FROM_PC; // PC
            aluB = ALU2_FROM_OP; // Shift from instruction
            aluFunc = 4'b0000;
            enPC = 1; // Write to PC
        end

        POP1: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_ALU;
            saveMem = 1;
        end

        POP2: begin
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;

            case (s1) // Destination
                DEST_A: enA = 1;
                DEST_B: enB = 1;
                DEST_C: enC = 1;
                DEST_ADR: begin
                    we = 1;
                    writeDataSource = WRITE_FROM_ALU;
                    memAddr = READ_FROM_A;
                end
                DEST_ABS, DEST_ABSI: begin
                    saveResult = 1;

                    memAddr = READ_FROM_PC; // Read value (PC)
                    saveMem = 1;
                end
            endcase
        end

        PUSH1: begin
            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;

            we = 1;
            writeDataSource = WRITE_FROM_ALU;
            memAddr = READ_FROM_SP; // Write Data
        end

        PUSH2: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0000;
            enSP = 1; // Increment SP

            memAddr = READ_FROM_ALU;
            saveMem = 1;
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

        RABSOLUTE1, RABSOLUTEI1: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value (PC)
            saveMem = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        RABSOLUTE2: begin // Read immediate value
            memAddr = READ_FROM_ALU; // Read value ((PC))
            saveMem = 1;

            aluFunc = 4'b0000; // (PC) + 0
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
        end

        RABSOLUTEI2: begin // Read immediate value
            memAddr = READ_FROM_ALU; // Read value ((PC) + A)
            saveMem = 1;

            aluFunc = 4'b0000; // (PC) + A
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_A;
        end

        WABSOLUTE1, WABSOLUTEI1: begin // Read immediate value
            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        WABSOLUTE2: begin
            memAddr = READ_FROM_ALU; // Write value ((PC))
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + 0
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
        end

        WABSOLUTEI2: begin
            memAddr = READ_FROM_ALU; // Write value ((PC) + A)
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + A
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_A;
        end
    endcase
end
endmodule
