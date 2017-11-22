# RCPU
This is small 16-bit CPU, written in Verilog 2001.  
It doesn't serve any specific purpose and was made just for fun.

## Registers
RCPU has 3 addressable 16-bit registers: **A**, **B** and **C**.
Also it has 32-bit **Program Counter** (PC), 4-bit **Flag Register** (F), 16-bit **Stack Pointer** (SP),
16-bit **Frame Pointer** (FP)
and some other internal registers about which you shouldn't worry.

## Addressing modes

- **Register** : Simply use value from A, B or C registers. (_In binary, it's_ `001`-`011`. `000` - _simply use 0_)
- **Immediate Small** : 8-bit constant is inside instruction code (_See I Type instructions_)
- **Immediate Big** : 16-bit constant after opcode (`100`)
- **Absolute** : Use 16-bit value at the 32-bit address, specified after opcode (`101`)
- **Addressed** : Use 16-bit value at the 32-bit address, specified by A register and page register (`110`)
- **Stack** : Use 16-bit value at the 32-bit address, specified by sum of 16-bit value after opcode and in FP register (`111`)
- **Pseudo Absolute** : Use address, specified by 15-bit value in instruction code and high 17-bit of current PC value
(_See J Type instructions_)

_Adresses are little-endian_

## Reserved port addresses

| Address    | Direction | Name       | Description                            |
|------------|-----------|------------|----------------------------------------|
| `FFFF0000` | Write     | `LCD_DATA` | LCD D0-D7 pins                         |
| `FFFF0001` | Write     | `LCD_CTRL` | LCD control pins                       |
| `FFFF1000` | Write     | `PAGE_REG` | High 16 bits for addressed memory mode |
| `FFFFFFFD` | Write     | `INT_EN`   | Interrupt enable                       |
| `FFFFFFFE` | Write     | `INT_LOW`  | Interrupt address low 16 bits          |
| `FFFFFFFF` | Write     | `INT_HIGH` | Interrupt address high 16 bits         |

## Flags

| C | N | Z | V |
|---|---|---|---|
| 3 | 2 | 1 | 0 |

- **C**arry flag - set if previous operation resulted unsigned overflow.
- **N**egative flag - set if previous operation result is negative number.
- **Z**egative flag - set if previous operation result is 0.
- O**v**erflow flag - set if previous operation resulted signed overflow.

## Instruction Set
_R - register  
M - memory address  
I - immediate value  
F - fast memory address
A0, A1, A2 - arguments of instruction_  

### A Type
| `0000` | Source 1 | Opcode | Source 2 | Destination |
|--------|----------|--------|----------|-------------|
| 4 bits | 3 bits   | 4 bits | 2 bits   | 3 bits      |

**Flags**: CNZV

Opcode |        Syntax        |     Description         | Formal Actions
-------|----------------------|-------------------------|--------------------
`0000` | `ADD `_`RMI, R, RM`_ | Addition                | `A3 <= A1 + A2`
`0001` | `ADC `_`RMI, R, RM`_ | Addition with carry     | `A3 <= A1 + A2 + C`
`0010` | `SUB `_`RMI, R, RM`_ | Substraction            | `A3 <= A1 - A2`
`0011` | `SBC `_`RMI, R, RM`_ | Substraction with carry | `A3 <= A1 - A2 - C`
`0100` | `MUL `_`RMI, R, RM`_ | Multiplication (32-bit) | `{A, A3} <= A1 * A2`
`0101` | `MLL `_`RMI, R, RM`_ | Multiplication (16-bit) | `A3 <= A1 * A2`
`0110` | `SGN `_`RMI, R, RM`_ | Set sign of value       | `A3 <= {A1[15], A2[14:0]`
`0111` | `RAS `_`RMI, R, RM`_ | Right arithmetic shift  | `A3 <= A1 >>> A2`
`1000` | `LSH `_`RMI, R, RM`_ | Left logical shift      | `A3 <= A1 << A2`
`1001` | `RSH `_`RMI, R, RM`_ | Right logical shift     | `A3 <= A1 >> A2`
`1010` | `LRT `_`RMI, R, RM`_ | Left cyclic shift       | `A3 <= A1 <cyclic< A2`
`1011` | `RRT `_`RMI, R, RM`_ | Right cyclic shift      | `A3 <= A1 >cyclic> A2`
`1100` | `AND `_`RMI, R, RM`_ | Bitwise and             | `A3 <= A1 & A2`
`1101` | `OR  `_`RMI, R, RM`_ | Bitwise or              | `A3 <= A1 \| A2`
`1110` | `XOR `_`RMI, R, RM`_ | Bitwise xor             | `A3 <= A1 ^ A2`
`1111` | `NOT `_`RMI, RM`_    | Bitwise not             | `A2 <= ~A1`

### J Type
|  `0`  | Address |
|-------|---------|
| 1 bit | 15 bits |

**Flags**: ----

  Syntax     |     Description                | Formal Actions
-------------|--------------------------------|--------------------
 `JMP `_`M`_ | Jump to given address          | `PC <= {PC[31:15], A1}`

### I Type
|  `01`  | Opcode | Source 1 | Opcode(continue) | Immediate |
|--------|--------|----------|------------------|-----------|
| 2 bits | 2 bits |  3 bits  | 1 bit            | 8 bits    |

**Flags**: CNZV

Opcode |     Syntax           |     Description                      | Formal Actions
-------|----------------------|--------------------------------------|--------------------
`00,0` | `ADDI `_`RM, I, RM`_ | Add immediate value                  | `A3 <= A1 + A2`
`01,0` | `ADCI `_`RM, I, RM`_ | Add immediate value with carry       | `A3 <= A1 + A2 + C`
`10,0` | `SUBI `_`RM, I, RM`_ | Substract immediate value            | `A3 <= A1 - A2`
`11,0` | `SBCI `_`RM, I, RM`_ | Substract immediate value with carry | `A3 <= A1 - A2 - C`
`00,1` | `ANDI `_`RM, I, RM`_ | Bitwise and with immediate value     | `A3 <= A1 & A2`
`01,1` | `ORI  `_`RM, I, RM`_ | Bitwise or with immediate value      | `A3 <= A1 \| A2`
`10,1` | `XORI `_`RM, I, RM`_ | Bitwise xor with immediate value     | `A3 <= A1 ^ A2`
`11,1` | `LDI `_`I, RM`_      | Load immediate value                 | `A3 <= A2`

*Restriction: First and third argument (destination) should use the same addressing mode!*
_If A1 == 0, then use SP_

### SI Type
| `0001` | Source 1 | Opcode | Destination | Immediate |
|--------|----------|--------|-------------|-----------|
| 4 bits |  3 bits  | 2 bits |   3 bits    |   4 bits  |

**Flags**: CNZV

Opcode |     Syntax            |     Description                        | Formal Actions
-------|-----------------------|----------------------------------------|--------------------
`00`   | `LSHI `_`RMI, I, RM`_ | Left logical shift at immediate value  | `A3 <= A1 << A2`
`01`   | `RSHI `_`RMI, I, RM`_ | Right logical shift at immediate value | `A3 <= A1 >> A2`
`10`   | `LRTI `_`RMI, I, RM`_ | Left cyclic shift at immediate value   | `A3 <= A1 <cyclic< A2`
`11`   | `RRTI `_`RMI, I, RM`_ | Right cyclic shift at immediate value  | `A3 <= A1 >cyclic> A2`

### F Type
| `00100` | Opcode |  Flag  | Immediate (address shift) |
|---------|--------|--------|---------------------------|
| 5 bits  | 1 bit  | 2 bits |          8 bits           |

**Flags**: ????

Opcode |   Syntax       |     Description                   | Formal Actions
-------|----------------|-----------------------------------|--------------------
`0`    | `JFC `_`M, I`_ | If flag is clear, jump to address | `if(!F[A2]) PC <= PC + A1`
`1`    | `JFS `_`M, I`_ | If flag is set, jump to address   | `if(F[A2]) PC <= PC + A1`

_Before jumping PC increments at fetching cycle, so actual jump address is `PC + A1 + 1`_

### LS Type
| `00101` | Opcode | Source/Destination | Fast memory address |
|---------|--------|--------------------|---------------------|
| 5 bits  | 1 bit  |       3 bits       |       7 bits        |

**Flags**: ????

Opcode |      Syntax       |     Description                   | Formal Actions
-------|-------------------|-----------------------------------|--------------------
`0`    | `LOAD `_`F, RM`_  | Load value from fast memory       | `fmem[A2] <= A1`
`1`    | `SAVE `_`RMI, F`_ | Save value to fast memory         | `A1 <= fmem[A2]`

_Fast memory is a register based memory, address to which is specified by `@address` syntax, which can be used only
in LS-type commands. It is also mapped to FFFF1000-FFFF107F addresses of normal memory space_

### SP Type
| `0011` | Source/Destination | Opcode | Unused |
|--------|--------------------|--------|--------|
| 4 bits |       3 bits       | 2 bits | 7 bits |

**Flags**: CNZV (if POP)

Opcode |   Syntax          |     Description           | Formal Actions
-------|-------------------|---------------------------|--------------------
`00`   | `PUSH `_`RMI`_    | Push value to stack       | `mem[SP] <= A1; SP <= SP - 1`
`01`   | `POP  `_`RM`_     | Pop value from stack      | `SP <= SP + 1; A1 <= mem[SP]`
`10`   | `SVPC`            | Push PC and FP to stack   | `mem[SP:SP-1] <= PC; mem[SP-2:SP-3] <= FP; SP <= SP - 4`
`11`   | `RET`             | Load PC and FP from stack | `SP <= SP + 4; PC <= mem[SP:SP-1] ; FP <= mem[SP-2:SP-3]`
_If in `POP` instruction 0 is used as destination, then load to flag register_

## Macro Instructions
|        Macro       |      Actual commands     |
|--------------------|--------------------------|
| `MOV `_`RMI, RMI`_ | `ADD A1, 0, A2`          |
| `JVC `_`M`_        | `JFC A1 0`               |
| `JVS `_`M`_        | `JFS A1 0`               |
| `JNE `_`M`_        | `JFC A1 1`               |
| `JEQ `_`M`_        | `JFS A1 1`               |
| `JGE `_`M`_        | `JFC A1 2`               |
| `JLT `_`M`_        | `JFS A1 2`               |
| `JCC `_`M`_        | `JFC A1 3`               |
| `JCS `_`M`_        | `JFS A1 3`               |
| `CALL `_`M`_       | `SVPC; JMP A1`           |
| `HALT`             | `JMP <current address>`  |
| `DW`_`I`_          | `<raw data in A1>`       |

# Links

PS/2 controller which I used in this project because mine was awful:  
http://www.eecg.toronto.edu/%7Ejayar/ece241_08F/AudioVideoCores/ps2/ps2.html
