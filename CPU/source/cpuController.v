module  cpuController( // CPU control unit (FSM)
    input wire clk,
    input wire rst,
    input wire[15:0] opcode, // Current instruction
    input wire[3:0] flags, // Current flag register
    input wire stall,
    input wire irq,

    output reg[1:0] memAddr, // Source of memory address
    output reg enPC, // Enable write to program counter
    output reg saveOpcode, // Enable write to instruction register
    output reg saveMem1, // Enable write to internal value register
    output reg saveMem2, // Enable write to internal value register
    output reg enFP, // Enable write to frame pointer
    output reg[3:0] aluFunc, // ALU control bus
    output reg[3:0] aluA, // Source of ALU input A
    output reg[3:0] aluB, // Source of ALU input B
    output reg enA,
    output reg enB,
    output reg enC,
    output reg we,
    output reg re,
    output reg[3:0] writeDataSource, // Source of data for writing to memory
    output reg saveResult, // Enable write to internal result register
    output reg enF, // Enable write to flag register
    output reg sourceF,
    output reg sourceFP,
    output reg[1:0] sourcePC,
    output reg[3:0] inF, // Alternative input to flag register
    output reg enSP, // Enable write to stack pointer
    output reg turnOffIRQ,
    output reg readStack,
    output reg isMul,
     // For debugging only
    output reg[5:0] state
     );

`include "constants"
// FSM states
parameter [5:0] HALT = 6'b111111; // CPU stop
parameter [5:0] START = 6'b000000;
parameter [5:0] FETCH = 6'b000001;
parameter [5:0] ATYPE = 6'b000010;
parameter [5:0] ITYPE = 6'b000011;
parameter [5:0] JTYPE = 6'b000100;
parameter [5:0] SITYPE = 6'b000101;
parameter [5:0] JFGINSTR = 6'b000110; // JFS/JFC
parameter [5:0] FLGINSTR = 6'b000111; // FLS/FLC
parameter [5:0] PUSH1 = 6'b001000;
parameter [5:0] PUSH2 = 6'b001001;
parameter [5:0] POP1 = 6'b001010;
parameter [5:0] POP2 = 6'b001011;
parameter [5:0] RET1 = 6'b001100;
parameter [5:0] RET2 = 6'b001101;
parameter [5:0] RET3 = 6'b001110;
parameter [5:0] RET4 = 6'b001111;
parameter [5:0] SVPC1 = 6'b010000;
parameter [5:0] SVPC2 = 6'b010001;
parameter [5:0] SVPC3 = 6'b010010;
parameter [5:0] SVPC4 = 6'b010011;
// Read states
parameter [5:0] RIMMED = 6'b010100;
parameter [5:0] RADDRESS = 6'b010101;
parameter [5:0] RABSOLUTE1_1 = 6'b010110;
parameter [5:0] RABSOLUTE1_2 = 6'b010111;
parameter [5:0] RABSOLUTE2 = 6'b011000;
parameter [5:0] RSTACK1 = 6'b011001;
parameter [5:0] RSTACK2 = 6'b011010;
// Write states
parameter [5:0] WABSOLUTE1_1 = 6'b011011;
parameter [5:0] WABSOLUTE1_2 = 6'b011100;
parameter [5:0] WSTACK1 = 6'b011101;
parameter [5:0] WSTACK2 = 6'b011110;
parameter [5:0] WABSOLUTE2 = 6'b011111;
parameter [5:0] WABSOLUTEI2 = 6'b100000;
parameter [5:0] INTERRUPT1 = 6'b100001;
parameter [5:0] INTERRUPT2 = 6'b100010;
parameter [5:0] INTERRUPT3 = 6'b100011;
parameter [5:0] INTERRUPT4 = 6'b100100;
parameter [5:0] INTERRUPT5 = 6'b100101;
parameter [5:0] INTERRUPT6 = 6'b100110;
parameter [5:0] INTERRUPT7 = 6'b100111;
parameter [5:0] INTERRUPT8 = 6'b101000;

//reg[5:0] state; // Current FSM state
reg[5:0] nextState; // Next FSM state

reg[5:0] returnState; // State to which FSM will return after reading value

wire[2:0] s1 = opcode[11:9]; // Source 1 field of opcode (common for all)

always @ (posedge clk) begin // FSM sequential logic
    if (rst) begin // Reset of all state registes
        state <= START;
    end else if (!stall) begin
        state <= nextState; // Go to next state
    end
end

always @ (*) begin // Next FSM state logic (combinational)
    nextState = HALT; // If invalid state, then stop CPU
        case (state)
        START: nextState = FETCH;
        FETCH: begin
            if (irq)
                nextState = INTERRUPT1;
            // If read addressing mode == register
            else if (s1[2] == 1'b0
                || (returnState != ATYPE &&
                    returnState != ITYPE &&
                    returnState != SITYPE &&
                    returnState != PUSH1)
                || (returnState == ITYPE && 
                    opcode[8] == 1'b1 && 
                    opcode[13:12] == 2'b11))
                nextState = returnState; // To main state of instruction type
            else if (s1 == 3'b100) // If read addressing mode == immediate
            nextState = RIMMED;
            else if (s1 == 3'b101) // If read addressing mode == absolute
            nextState = RABSOLUTE1_1;
            else if (s1 == 3'b110) // If read addressing mode == address
            nextState = RADDRESS;
            // If read addressing mode == absolute indexed
            else if (s1 == 3'b111)
            nextState = RSTACK1;
            end
        JTYPE, JFGINSTR, FLGINSTR, PUSH2, RET3, SVPC3: nextState = FETCH;
            // Fetch next instruction
        ATYPE:
            if (opcode[2:0] == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (opcode[2:0] == DEST_ABSI) nextState = WSTACK1;
            else nextState = FETCH;
        ITYPE:
            if (s1 == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (s1 == DEST_ABSI) nextState = WSTACK1;
            else nextState = FETCH;
        SITYPE:
            if (opcode[6:4] == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (opcode[6:4] == DEST_ABSI) nextState = WSTACK1;
            else nextState = FETCH;
        POP2:
            if (s1 == DEST_ABS) nextState = WABSOLUTE1_1;
            else if (s1 == DEST_ABSI) nextState = WSTACK1;
            else nextState = FETCH;
        // To main state of instruction type
        RIMMED, RADDRESS, RABSOLUTE2, RSTACK2: nextState = returnState;
        RABSOLUTE1_1: nextState = RABSOLUTE1_2;
        WABSOLUTE1_1: nextState = WABSOLUTE1_2;
        RABSOLUTE1_2: nextState = RABSOLUTE2;
        WABSOLUTE1_2: nextState = WABSOLUTE2;
        WABSOLUTE2, WSTACK2: nextState = FETCH;
        RSTACK1: nextState = RSTACK2;
        WSTACK1: nextState = WSTACK2;
        PUSH1: nextState = PUSH2;
        POP1: nextState = POP2;
        SVPC1: nextState = SVPC2;
        SVPC2: nextState = SVPC3;
        RET1: nextState = RET2;
        RET2: nextState = RET3;
        INTERRUPT1: nextState = INTERRUPT2;
        INTERRUPT2: nextState = INTERRUPT3;
        INTERRUPT3: nextState = INTERRUPT4;
        INTERRUPT4: nextState = INTERRUPT5;
        INTERRUPT5: nextState = INTERRUPT6;
        INTERRUPT6: nextState = INTERRUPT7;
        INTERRUPT7: nextState = INTERRUPT8;
        INTERRUPT8: nextState = FETCH;
        default: nextState = HALT;
        endcase
    end

reg isFLG;

always @ ( * ) begin // returnState calculation logic (combinational)
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
        case (opcode[8:7])
            2'b00: returnState = PUSH1;
            2'b01: returnState = POP1;
            2'b10: returnState = SVPC1;
            2'b11: returnState = RET1;
        endcase
end

always @ (*) begin // Output logic
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
    sourceFP = 0;
    sourcePC = 0;
    inF = 0;
    enSP = 0;
    enFP = 0;
    re = 0;
    turnOffIRQ = 0;
    readStack = 0;
    isMul = 0;
    case (state)
        START: begin
        end
        FETCH: begin
            if (!irq) begin
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
        end

        ATYPE: begin
            if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = opcode[4:3]; // Source for ALU input B
            aluFunc = opcode[8:5]; // ALU control is in the instruction
            enF = 1; // Update flags
            if (opcode[8:5] == 4'b0100) begin // If MUL instruction
                enA = 1;
                isMul = 1;
            end
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
                default: begin end
            endcase
        end

        ITYPE: begin
            if (s1 == 3'b000)// If reading from SP
                aluA = ALU1_FROM_SP;
            else if (s1[2] == 1'b0) // If reading from register
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            // ALU control is in pattern 3312 if opcode - 12|3
            aluFunc = {opcode[8], opcode[8], opcode[13:12]};
            aluB = ALU2_FROM_OP; // Source for ALU input B
            enF = 1; // Update flags
            case (s1) // Destination
                DEST_0: enSP = 1;
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
                default: begin end
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
                default: begin end
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
            aluFunc = 4'b0000;
            enSP = 1; // Increment SP

            memAddr = READ_FROM_ALU;
            readStack = 1;
            saveMem1 = 1;
            re = 1;
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
                    saveMem1 = 1;
                end
                default: begin end
            endcase
        end

        PUSH1: begin
            if (s1[2] == 1'b0) // If reading from register or 0
                aluA = s1[1:0];
            else // If reading from memory
                aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;

            we = 1;
            readStack = 1;
            writeDataSource = WRITE_FROM_ALU;
            memAddr = READ_FROM_SP; // Write Data
        end


        PUSH2: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP
        end

        SVPC1, INTERRUPT1: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_SP;
            readStack = 1;
            writeDataSource = WRITE_FROM_PC2;
            we = 1; // Write high PC bits
        end
        SVPC2: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_SP;
            readStack = 1;
            writeDataSource = WRITE_FROM_PC1P1;
            we = 1; // Write low PC bits
        end
        SVPC3, INTERRUPT3: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP
            enFP = 1;

            memAddr = READ_FROM_SP;
            readStack = 1;
            writeDataSource = WRITE_FROM_FP;
            we = 1; // Write FP
        end

        RET1: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0000;
            enSP = 1; // Increment SP

            memAddr = READ_FROM_ALU;
            readStack = 1;
            re = 1;
            sourceFP = 1;
            enFP = 1;
        end

        RET2: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0000;
            enSP = 1; // Increment SP

            memAddr = READ_FROM_ALU;
            readStack = 1;
            re = 1;
            sourcePC = 1;
            enPC = 1;
        end

        RET3: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0000;
            enSP = 1; // Increment SP

            memAddr = READ_FROM_ALU;
            readStack = 1;
            re = 1;
            sourcePC = 2;
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

        WABSOLUTE1_1, RABSOLUTE1_1: begin // Read immediate value
            memAddr = READ_FROM_PC; // Read value (PC)
            saveMem2 = 1;
            re = 1;

            aluFunc = 4'b0000; // Increment PC
            aluA = ALU1_FROM_PC;
            aluB = ALU2_FROM_1;
            enPC = 1;
        end

        WABSOLUTE1_2, RABSOLUTE1_2, RSTACK1, WSTACK1: begin // Read immediate value
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

        RSTACK2: begin // Read from stack
            memAddr = READ_FROM_ALU; // Read value ((PC) + FP)
            readStack = 1;
            saveMem1 = 1;
            re = 1;

            aluFunc = 4'b0000; // (PC) + FP
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_FP;
        end

        WABSOLUTE2: begin
            memAddr = READ_FROM_ALU; // Write value to ((PC))
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + 0
            aluA = ALU1_FROM_HIMEM;
            aluB = ALU2_FROM_0;
        end

        WSTACK2: begin
            memAddr = READ_FROM_ALU; // Write value to ((PC) + FP)
            readStack = 1;
            we = 1;
            writeDataSource = WRITE_FROM_RES;

            aluFunc = 4'b0000; // (PC) + FP
            aluA = ALU1_FROM_MEM;
            aluB = ALU2_FROM_FP;
        end

        INTERRUPT2: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP
            turnOffIRQ = 1;

            memAddr = READ_FROM_SP;
            writeDataSource = WRITE_FROM_PC1;
            readStack = 1;
            we = 1; // Write low PC bits
        end

        INTERRUPT4: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_SP;
            writeDataSource = WRITE_FROM_INTDATA;
            readStack = 1;
            we = 1; // Write interrupt data
        end

        INTERRUPT5: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_SP;
            writeDataSource = WRITE_FROM_C;
            readStack = 1;
            we = 1; // Write C
        end
        INTERRUPT6: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP

            memAddr = READ_FROM_SP;
            writeDataSource = WRITE_FROM_B;
            readStack = 1;
            we = 1; // Write B
        end
        INTERRUPT7: begin
            aluA = ALU1_FROM_SP;
            aluB = ALU2_FROM_1;
            aluFunc = 4'b0010;
            enSP = 1; // Decrement SP
            enFP = 1;

            memAddr = READ_FROM_SP;
            writeDataSource = WRITE_FROM_A;
            readStack = 1;
            we = 1; // Write A
        end
        INTERRUPT8: begin
            aluA = ALU1_FROM_INTADDR; // Use interrupt address
            aluB = ALU2_FROM_0;
            aluFunc = 4'b0000;
            enPC = 1; // Write to PC
        end
        default: begin end
    endcase
end
endmodule
