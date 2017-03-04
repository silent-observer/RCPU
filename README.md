# RCPU
This is small 16-bit CPU, written in Verilog 2001.

It doesn't serve any specific purpose and was made just for fun.

## Registers
RCPU has 3 addressable 16-bit registers: **A**, **B** and **C**.
Also it has 16-bit **Program Counter** (PC), 4-bit **Flag Register** (F) 
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
