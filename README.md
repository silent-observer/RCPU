# RCPU
This is small 16-bit CPU, written in Verilog 2001. <br>
It doesn't serve any specific purpose and was made just for fun.

## Registers
RCPU has 3 addressable 16-bit registers: **A**, **B** and **C**.
Also it has 16-bit **Program Counter** (PC), 4-bit **Flag Register** (F), 16-bit **Stack Pointer** (SP)
and some other internal registers about which you shouldn't worry.

## Addressing modes

- **Register** : Simply use value from A, B or C registers. (_In binary, it's_ `001`-`011`. `000` - _simply use 0_)
- **Immediate Small** : 8-bit constant is inside instruction code (_See I Type instructions_)
- **Immediate Big** : 16-bit constant after opcode (`100`)
- **Absolute** : Use 16-bit value at the address, specified after opcode (`101`)
- **Addressed** : Use 16-bit value at the address, specified by A register (`110`)
- **Absolute Indexed** : Use 16-bit value at the address, specified by sum of value after opcode and in A register (`110`)
- **Pseudo Absolute** : Use address, specified by 15-bit value in instruction code and high bit from current PC value
(_See J Type instructions_)

## Flags

| C | N | Z | V |
|---|---|---|---|

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

Opcode |        Syntax    |     Description         | Formal Actions
-------|------------------|-------------------------|--------------------
`0000` | `ADD R, RMI, RM` | Addition                | `A3 <= A1 + A2`
`0001` | `ADC R, RMI, RM` | Addition with carry     | `A3 <= A1 + A2 + C`
`0010` | `SUB R, RMI, RM` | Substraction            | `A3 <= A1 - A2`
`0011` | `SBC R, RMI, RM` | Substraction with carry | `A3 <= A1 - A2 - C`
`0100` | `MUL R, RMI, RM` | Multiplication (32-bit) | `{A, A3} <= A1 * A2`
`0101` | `MLL R, RMI, RM` | Multiplication (16-bit) | `A3 <= A1 * A2`
`0110` | `SGN R, RMI, RM` | Set sign of value       | `A3 <= {A1[15], A2[14:0]`
`0111` | `RAS R, RMI, RM` | Right arithmetic shift  | `A3 <= A1 >>> A2`
`1000` | `LSH R, RMI, RM` | Left logical shift      | `A3 <= A1 << A2`
`1001` | `RSH R, RMI, RM` | Right logical shift     | `A3 <= A1 >> A2`
`1010` | `LRT R, RMI, RM` | Left cyclic shift       | `A3 <= A1 <cyclic< A2`
`1011` | `RLT R, RMI, RM` | Right cyclic shift      | `A3 <= A1 >cyclic> A2`
`1100` | `AND R, RMI, RM` | Bitwise and             | `A3 <= A1 & A2`
`1101` | `OR  R, RMI, RM` | Bitwise or              | `A3 <= A1 | A2`
`1110` | `XOR R, RMI, RM` | Bitwise xor             | `A3 <= A1 ^ A2`
`1111` | `NOT RMI, RM`    | Bitwise not             | `A2 <= ~A1`

### J Type
|  `0`  | Address |
|-------|---------|
| 1 bit | 15 bits |
**Flags**: ----

  Syntax  |     Description                | Formal Actions
----------|--------------------------------|--------------------
 `JMP M`  | Jump to given address          | `PC <= {PC[15], A1}`

### I Type
|  `01`  | Opcode | Source 1 | Opcode(continue) | Immediate |
|--------|--------|----------|------------------|-----------|
| 2 bits | 2 bits |  3 bits  | 1 bit            | 8 bits    |
**Flags**: CNZV

Opcode |     Syntax   |     Description                | Formal Actions
-------|--------------|--------------------------------------|--------------------
`00|0`  | `ADDI RM, I` | Add immediate value                  | `A1 <= A1 + A2`
`01|0`  | `ADCI RM, I` | Add immediate value with carry       | `A1 <= A1 + A2 + C`
`10|0`  | `SUBI RM, I` | Substract immediate value            | `A1 <= A1 - A2`
`11|0`  | `SBCI RM, I` | Substract immediate value with carry | `A1 <= A1 - A2 - C`
`00|1`  | `ANDI RM, I` | Bitwise and with immediate value     | `A1 <= A1 & A2`
`01|1`  | `ORI  RM, I` | Bitwise or with immediate value      | `A1 <= A1 | A2`
`10|1`  | `XORI RM, I` | Bitwise xor with immediate value     | `A1 <= A1 ^ A2`
`11|1`  | ???          | Unused opcode                        |

### SI Type
| `0001` | Source 1 | Opcode | Destination | Immediate |
|--------|----------|--------|-------------|-----------|
| 4 bits |  3 bits  | 2 bits |   3 bits    |   4 bits  |
**Flags**: CNZV

Opcode |     Syntax        |     Description                        | Formal Actions
-------|-------------------|----------------------------------------|--------------------
`00`   | `LSHI RMI, I, RM` | Left logical shift at immediate value  | `A3 <= A1 << A2`
`01`   | `RSHI RMI, I, RM` | Right logical shift at immediate value | `A3 <= A1 >> A2`
`10`   | `LRTI RMI, I, RM` | Left cyclic shift at immediate value   | `A3 <= A1 <cyclic< A2`
`11`   | `RRTI RMI, I, RM` | Right cyclic shift at immediate value  | `A3 <= A1 >cyclic> A2`

### F Type
| `010000` | Opcode |   C    |   N    |   Z    |   V    |
|----------|--------|--------|--------|--------|--------|
|  6 bits  | 2 bits | 2 bits | 2 bits | 2 bits | 2 bits |
**Flags**: ????

Opcode |   Syntax     |     Description                                     | Formal Actions
-------|--------------|-----------------------------------------------------|--------------------
`00`   | `JFA M, I`   | If all of flag conditions are true, jump to address | `if(& cond) PC <= A1`
`01`   | `JFO M, I`   | If any of flag conditions are true, jump to address | `if(| cond) PC <= A1`
`10`   | `FLG I`      | Set chosen flags to chosen values                   | `Fn <= An1 ? An2 : Fn`
`11`   | ???          | Unused opcode                                       |

_Flag condition is given by 2 bits for each flag: first bit is set if flag matters the result (or if it should be changed)
, second bit shows if flag should be set or clear (or to which state flag should be changed)_

### SP Type
| `0011` | Opcode | Source/Destination | Unused |
|--------|--------|--------------------|--------|
| 4 bits |  1 bit | 4 bits             | 7 bits |
**Flags** ----

Opcode |   Syntax     |     Description      | Formal Actions
-------|--------------|----------------------|--------------------
`0`    | `PUSH RMI`   | Push value to stack  | `mem[SP] <= A1; SP <= SP + 1`
`1`    | `POP  RMI`   | Pop value from stack | `SP <= SP - 1; A1 <= mem[SP]`

_Source value 1000 means PC register, 1001 - flag register_
