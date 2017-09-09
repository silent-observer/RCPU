# RCPU
This is small 16-bit CPU, written in Verilog 2001. <br>
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
- **Addressed** : Use 16-bit value at the 32-bit address, specified by A register (`110`)
- **Stack** : Use 16-bit value at the 32-bit address, specified by sum of 16-bit value after opcode and in FP register (`111`)
- **Pseudo Absolute** : Use address, specified by 15-bit value in instruction code and high 17-bit of current PC value
(_See J Type instructions_)

_Adresses are little-endian_

## Flags

| C | N | Z | V |
|---|---|---|---|
| 3 | 2 | 1 | 0 |

- **C**arry flag - set if previous operation resulted unsigned overflow.
- **N**egative flag - set if previous operation result is negative number.
- **Z**egative flag - set if previous operation result is 0.
- O**v**erflow flag - set if previous operation resulted signed overflow.

## Instruction Set
_R - register <br>
M - memory address <br>
I - immediate value <br>
A0, A1, A2 - arguments of instruction_ <br>

### A Type
| `0000` | Source 1 | Opcode | Source 2 | Destination |
|--------|----------|--------|----------|-------------|
| 4 bits | 3 bits   | 4 bits | 2 bits   | 3 bits      |

**Flags**: CNZV

Opcode |        Syntax        |     Description         | Formal Actions
-------|----------------------|-------------------------|--------------------
`0000` | `ADD `_`R, RMI, RM`_ | Addition                | `A3 <= A1 + A2`
`0001` | `ADC `_`R, RMI, RM`_ | Addition with carry     | `A3 <= A1 + A2 + C`
`0010` | `SUB `_`R, RMI, RM`_ | Substraction            | `A3 <= A1 - A2`
`0011` | `SBC `_`R, RMI, RM`_ | Substraction with carry | `A3 <= A1 - A2 - C`
`0100` | `MUL `_`R, RMI, RM`_ | Multiplication (32-bit) | `{A, A3} <= A1 * A2`
`0101` | `MLL `_`R, RMI, RM`_ | Multiplication (16-bit) | `A3 <= A1 * A2`
`0110` | `SGN `_`R, RMI, RM`_ | Set sign of value       | `A3 <= {A1[15], A2[14:0]`
`0111` | `RAS `_`R, RMI, RM`_ | Right arithmetic shift  | `A3 <= A1 >>> A2`
`1000` | `LSH `_`R, RMI, RM`_ | Left logical shift      | `A3 <= A1 << A2`
`1001` | `RSH `_`R, RMI, RM`_ | Right logical shift     | `A3 <= A1 >> A2`
`1010` | `LRT `_`R, RMI, RM`_ | Left cyclic shift       | `A3 <= A1 <cyclic< A2`
`1011` | `RRT `_`R, RMI, RM`_ | Right cyclic shift      | `A3 <= A1 >cyclic> A2`
`1100` | `AND `_`R, RMI, RM`_ | Bitwise and             | `A3 <= A1 & A2`
`1101` | `OR  `_`R, RMI, RM`_ | Bitwise or              | `A3 <= A1 \| A2`
`1110` | `XOR `_`R, RMI, RM`_ | Bitwise xor             | `A3 <= A1 ^ A2`
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

Opcode |     Syntax       |     Description                      | Formal Actions
-------|------------------|--------------------------------------|--------------------
`00,0` | `ADDI `_`RM, I`_ | Add immediate value                  | `A1 <= A1 + A2`
`01,0` | `ADCI `_`RM, I`_ | Add immediate value with carry       | `A1 <= A1 + A2 + C`
`10,0` | `SUBI `_`RM, I`_ | Substract immediate value            | `A1 <= A1 - A2`
`11,0` | `SBCI `_`RM, I`_ | Substract immediate value with carry | `A1 <= A1 - A2 - C`
`00,1` | `ANDI `_`RM, I`_ | Bitwise and with immediate value     | `A1 <= A1 & A2`
`01,1` | `ORI  `_`RM, I`_ | Bitwise or with immediate value      | `A1 <= A1 \| A2`
`10,1` | `XORI `_`RM, I`_ | Bitwise xor with immediate value     | `A1 <= A1 ^ A2`
`11,1` | `LDI `_`RM, I`_  | Load immediate value                 | `A1 <= A2`

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
| `0010` | Opcode |  Flag  | Immediate (address shift) |
|--------|--------|--------|---------------------------|
| 4 bits | 2 bits | 2 bits |          8 bits           |

**Flags**: ????

Opcode |   Syntax       |     Description                   | Formal Actions
-------|----------------|-----------------------------------|--------------------
`00`   | `JFC `_`M, I`_ | If flag is clear, jump to address | `if(!F[A2]) PC <= PC + A1`
`01`   | `JFS `_`M, I`_ | If flag is set, jump to address   | `if(F[A2]) PC <= PC + A1`
`10`   | `FLC `_`I`_    | Clear chosen flag                 | `F[A1] <= 0`
`11`   | `FLS `_`I`_    | Set chosen flag                   | `F[A1] <= 1`

_Before jumping with `JFC`/`JFS` instructions PC increments at fetching cycle, so actual jump address is `PC + A1 + 1`_

### SP Type
| `0011` | Source/Destination | Opcode | Unused |
|--------|--------------------|--------|--------|
| 4 bits |       3 bits       | 2 bits | 7 bits |

**Flags**: CNZV (if POP)

Opcode |   Syntax          |     Description           | Formal Actions
-------|-------------------|---------------------------|--------------------
`00`   | `PUSH `_`RMI`_    | Push value to stack       | `mem[SP] <= A1; SP <= SP - 1`
`01`   | `POP  `_`RMI`_    | Pop value from stack      | `SP <= SP + 1; A1 <= mem[SP]`
`10`   | `SVPC`            | Push PC and FP to stack   | `mem[SP:SP-1] <= PC; mem[SP-2:SP-3] <= FP; SP <= SP - 4`
`11`   | `RET`             | Load PC and FP from stack | `SP <= SP + 4; PC <= mem[SP:SP-1] ; FP <= mem[SP-2:SP-3]`

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
