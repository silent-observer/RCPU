module  cpuController( // CPU control unit (FMA)
    input wire clk, // Clock
    input wire rst, // Reset
    input wire[15:0] opcode, // Current instruction
    input wire[3:0] flags, // Current flag register

    output reg[1:0] memAddr, // Source of memory address
    output reg enPC, // Enable write to program counter
    output reg saveOpcode, // Enable write to instruction register
    output reg saveMem1, // Enable write to internal value register
    output reg saveMem2, // Enable write to internal value register
    output reg[3:0] aluFunc, // ALU control bus
    output reg[3:0] aluA, // Source of ALU input A
    output reg[2:0] aluB, // Source of ALU input B
    output reg enA, // Enable write to A register
    output reg enB, // Enable write to B register
    output reg enC, // Enable write to C register
    output reg we, // Enable write to memory
    output reg re,
    output reg writeDataSource, // Source of data for writing to memory
    output reg saveResult, // Enable write to internal result register
    output reg enF, // Enable write to flag register
    output reg sourceF, // Source of input to flag register
    output reg[3:0] inF, // Alternative input to flag register
    output reg enSP, // Enable write to stack pointer
    output reg initSP
    );

`include "../source/constants"
parameter [5:0] START = 6'b001111; // Start
parameter [5:0] FETCH = 6'b000000; // Instruction fetching cycle
parameter [5:0] ATYPE = 6'b000001; // Execution of A Type instructions
parameter [5:0] ITYPE = 6'b000010; // Execution of I Type instructions
parameter [5:0] JTYPE = 6'b000011; // Execution of J Type instructions
parameter [5:0] SITYPE = 6'b000100; // Execution of SI Type instructions
parameter [5:0] JFGINSTR = 6'b000101; // Execution of JFS/JFC instructions
parameter [5:0] FLGINSTR = 6'b000110; // Execution of FLS/FLC instructions
parameter [5:0] PUSH1 = 6'b001000; // Execution of PUSH instruction
parameter [5:0] PUSH2 = 6'b001001;
parameter [5:0] POP1 = 6'b001010; // Execution of POP instruction
parameter [5:0] POP2 = 6'b001011;
parameter [5:0] RET1 = 6'b001100; // Execution of RET instruction
parameter [5:0] RET2 = 6'b001101;
parameter [5:0] RET3 = 6'b000111;
parameter [5:0] SVPC = 6'b001110; // Execution of SVPC instruction
parameter [5:0] HALT = 6'b111111; // CPU stop

parameter [5:0] RIMMED = 6'b010000; // Read immediate value
parameter [5:0] RADDRESS = 6'b010001; // Read adressed value
parameter [5:0] RABSOLUTE1_1 = 6'b010010; // Read absolute adressed value
parameter [5:0] RABSOLUTE1_2 = 6'b010011;
parameter [5:0] RABSOLUTE2 = 6'b010100;
parameter [5:0] RABSOLUTEI1_1 = 6'b010101; // Read absolute indexed value
parameter [5:0] RABSOLUTEI1_2 = 6'b010110;
parameter [5:0] RABSOLUTEI2 = 6'b010111;
parameter [5:0] RPC = 6'b011000;

parameter [5:0] WABSOLUTE1_1 = 6'b011001; // Write absolute adressed value
parameter [5:0] WABSOLUTE1_2 = 6'b011010;
parameter [5:0] WABSOLUTEI1_1 = 6'b011011; // Write absolute indexed value
parameter [5:0] WABSOLUTEI1_2 = 6'b011100;
parameter [5:0] WABSOLUTE2 = 6'b011101; // Write absolute adressed value
parameter [5:0] WABSOLUTEI2 = 6'b011110; // Write absolute indexed value
parameter [5:0] WPC = 6'b011111;

reg[5:0] state; // Current FSM state
reg[5:0] nextState; // Next FSM state

reg[5:0] returnState; // State to which FSM will return after reading value

wire[2:0] s1 = opcode[11:9]; // Source 1 field of opcode (common for all)

always @ (posedge clk or posedge rst) begin // FMS sequential logic
    if (rst) begin // Reset of all state registes
        state <= START;
    end else begin
        state <= nextState; // Go to next state
    end
end

always @ (*) begin
    nextState = HALT; // If invalid state, then stop CPU
    case (state)
        START: nextState = FETCH;
        FETCH: begin
            // If read addressing mode == register
            if ((returnState == PUSH1) && s1 == 3'b000)
                nextState = RPC;
            else if (returnState == POP2 && s1 == 3'b000)
                nextState = WPC;
            else if (s1[2] == 1'b0
                || (returnState != ATYPE &&
                    returnState != ITYPE &&
                    returnState != SITYPE &&
                    returnState != PUSH1 &&
                    returnState != SVPC))
                nextState = returnState; // To main state of instruction type
            else if (s1 == 3'b100) // If read addressing mode == immediate
                nextState = RIMMED;
            else if (s1 == 3'b101) // If read addressing mode == absolute
                nextState = RABSOLUTE1_1;
            else if (s1 == 3'b110) // If read addressing mode == address
                nextState = RADDRESS;
            // If read addressing mode == absolute indexed
            else if (s1 == 3'b111)
                nextState = RABSOLUTEI1_1;
        end
        JTYPE, JFGINSTR, FLGINSTR, PUSH2, RET3: nextState = FETCH;
            // Fetch next instruction
        ATYPE:
            if (opcode[2:0] == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (opcode[2:0] == DEST_ABSI) nextState = WABSOLUTEI1_1;
            else nextState = FETCH;
        ITYPE:
            if (s1 == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (s1 == DEST_ABSI) nextState = WABSOLUTEI1_1;
            else nextState = FETCH;
        SITYPE:
            if (opcode[6:4] == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (opcode[6:4] == DEST_ABSI) nextState = WABSOLUTEI1_1;
            else nextState = FETCH;
        POP2:
            if (s1 == DEST_0) nextState = WPC;
            else if (s1 == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (s1 == DEST_ABSI) nextState = WABSOLUTEI1_1;
            else nextState = FETCH;
        // To main state of instruction type
        RIMMED, RADDRESS, RABSOLUTE2, RABSOLUTEI2, RPC: nextState = returnState;
        RABSOLUTE1_1: nextState = RABSOLUTE1_2; // To next step
        RABSOLUTEI1_1: nextState = RABSOLUTEI1_2; // To next step
        WABSOLUTE1_1: nextState = WABSOLUTE1_2; // To next step
        WABSOLUTEI1_1: nextState = WABSOLUTEI1_2; // To next step
        RABSOLUTE1_2: nextState = RABSOLUTE2; // To next step
        RABSOLUTEI1_2: nextState = RABSOLUTEI2; // To next step
        WABSOLUTE1_2: nextState = WABSOLUTE2; // To next step
        WABSOLUTEI1_2: nextState = WABSOLUTEI2; // To next step
        WABSOLUTE2, WABSOLUTEI2, WPC: nextState = FETCH;
        PUSH1: nextState = PUSH2;
        POP1: nextState = POP2;
        SVPC: nextState = WPC;
        RET1: nextState = RET2;
        RET2: nextState = RET3;
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
        case (opcode[8:7]) // PUSH
            2'b00: returnState = PUSH1;
            2'b01: returnState = POP1;
            2'b10: returnState = SVPC;
            2'b11: returnState = RET1;
        endcase
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
    saveMem1 = 0;
    saveMem2 = 0;
    we = 0;
    writeDataSource = 0;
    saveResult = 0;
    enF = 0;
    sourceF = 0;
    inF = 0;
    enSP = 0;
    initSP = 0;
    re = 0;
    case (state)
        START: begin
            enSP = 1;
            initSP = 1;
        end
        FETCH: begin
            memAddr = READ_FROM_PC; // Fetch instruction
            re = 1;
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
                    saveMem1 = 1;
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
                    saveMem1 = 1;
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
            case (opcode[6:4]) // Destination
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
                    saveMem1 = 1;
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
            saveMem1 = 1;
            re = 1;
        end

        POP2: begin
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;
            case (s1) // Destination
                DEST_0: saveResult = 1;
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
                    saveMem1 = 1;
                end
            endcase
        end

        PUSH1: begin
            if (s1[2] == 1'b0 && s1 != 3'b000) // If reading from register
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
        end

        SVPC: begin
            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;

            saveResult = 1;
        end

        RET1: begin // Read from (000000xx)
            memAddr = READ_FROM_ALU; // Read value (000000xx)
            saveMem2 = 1;
            re = 1;

            aluFunc = 4'b0000; // XX + 1
            aluA = ALU1_FROM_XX;
            aluB = ALU2_FROM_0;
        end

        RET1: begin // Read from (000000xx+1)
            memAddr = READ_FROM_ALU; // Read value (000000xx+1)
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // XX + 0
            aluA = ALU1_FROM_XX;
            aluB = ALU2_FROM_1;
        end

        RET3: begin
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;
            enPC = 1;
        end

        RIMMED: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value from (PC)
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        RADDRESS: begin // Read immediate value
            memAddr = READ_FROM_A; // Read value from (A)
            saveMem1 = 1;
            re = 1;
        end

        WABSOLUTE1_1, WABSOLUTEI1_1,
        RABSOLUTE1_1, RABSOLUTEI1_1: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value (PC)
            saveMem2 = 1;
            re = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        WABSOLUTE1_2, WABSOLUTEI1_2,
        RABSOLUTE1_2, RABSOLUTEI1_2: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value (PC)
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        RABSOLUTE2: begin // Read immediate value
            memAddr = READ_FROM_ALU; // Read value ((PC))
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // (PC) + 0
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_0;
        end

        RPC: begin // Read from (000000xx)
            memAddr = READ_FROM_ALU; // Read value (000000xx)
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // XX + 0
            aluA = ALU1_FROM_XX;
            aluB = ALU2_FROM_0;
        end

        RABSOLUTEI2: begin // Read immediate value
            memAddr = READ_FROM_ALU; // Read value ((PC) + A)
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // (PC) + A
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_A;
        end

        WABSOLUTE2: begin
            memAddr = READ_FROM_ALU; // Write value ((PC))
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + 0
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_0;
        end

        WABSOLUTEI2: begin
            memAddr = READ_FROM_ALU; // Write value ((PC) + A)
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + A
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_A;
        end

        WPC: begin // Write to (000000xx)
            memAddr = READ_FROM_ALU; // Write value to (000000xx)
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // XX + 0
            aluA = ALU1_FROM_XX;
            aluB = ALU2_FROM_0;
        end
    endcase
end
endmodule
