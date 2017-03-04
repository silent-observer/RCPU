# RCPU
This is small 16-bit CPU, written in Verilog 2001. <br>
It doesn't serve any specific purpose and was made just for fun.

## Registers
RCPU has 3 addressable 16-bit registers: **A**, **B** and **C**.
Also it has 16-bit **Program Counter** (PC), 4-bit **Flag Register** (F), 16-bit **Stack Pointer** (SP) 
and some other internal registers about which you shouldn't worry.

## Addressing modes

- **Register** : Simply use value from A, B or C registers. (_In binary, it's_ `001`-`011`. `000`_ - symply use 0_)
- **Immediate Small** : 8-bit constant is inside instruction code (_See I Type instructions_)
- **Immediate Big** : 16-bit constant after opcode (`100`)
- **Absolute** : Use 16-bit value at the address, specified after opcode (`101`)
- **Addressed** : Use 16-bit value at the address, specified by A register (`110`)
- **Absolute Indexed** : Use 16-bit value at the address, specified by sum of value after opcode and in A register (`110`)
- **Pseudo Absolute** : Use address, specified by 14-bit value in instruction code and 2 high bits from current PC value 
(_See J Type instructions_)

## Flags

| C | N | Z | V |
|---|---|---|---|

- **C**arry flag - set if previous operation resulted unsigned overflow.
- **N**egative flag - set if previous operation result is negative number.
- **Z**egative flag - set if previous operation result is 0.
- O**v**erflow flag - set if previous operation resulted signed overflow.

## Instruction Set
_R - register
M - memory address
I - immediate value
A0, A1, A2 - arguments of instruction_

### A Type
|  0000  | Source 1 | Opcode | Source 2 | Destination |
|--------|----------|--------|----------|-------------|
| 4 bits | 3 bits   | 4 bits | 2 bits   | 3 bits      |
**Flags**: CNZV

Opcode |        Syntax         |     Description         | Formal Actions 
-------|-----------------------|-------------------------|--------------------
0000   | ADD _RMI_, _R_, _RMI_ | Addition                | A3 <= A1 + A2
0001   | ADC _RMI_, _R_, _RMI_ | Addition with carry     | A3 <= A1 + A2 + C
0010   | SUB _RMI_, _R_, _RMI_ | Substraction            | A3 <= A1 - A2
0011   | SBC _RMI_, _R_, _RMI_ | Substraction with carry | A3 <= A1 - A2 - C
0100   | MUL _RMI_, _R_, _RMI_ | Multiplication (32-bit) | {A, A3} <= A1 * A2
0101   | MLL _RMI_, _R_, _RMI_ | Multiplication (16-bit) | A3 <= A1 * A2
0110   | ???                   | Unused opcode           |
0111   | RAS _RMI_, _R_, _RMI_ | Right arithmetic shift  | A3 <= A1 >>> A2
1000   | LSH _RMI_, _R_, _RMI_ | Left logical shift      | A3 <= A1 << A2
1001   | RSH _RMI_, _R_, _RMI_ | Right logical shift     | A3 <= A1 >> A2
1010   | LRT _RMI_, _R_, _RMI_ | Left cyclic shift       | A3 <= A1 \<cyclic< A2
1011   | RLT _RMI_, _R_, _RMI_ | Right cyclic shift     | A3 <= A1 >cyclic> A2
1100   | AND _RMI_, _R_, _RMI_ | Bitwise and             | A3 <= A1 & A2
1101   | OR  _RMI_, _R_, _RMI_ | Bitwise or              | A3 <= A1 \& A2
1110   | XOR _RMI_, _R_, _RMI_ | Bitwise exclusive or    | A3 <= A1 ^ A2
1111   | NOT _RMI_, _RMI_      | Bitwise not             | A2 <= ~A1
