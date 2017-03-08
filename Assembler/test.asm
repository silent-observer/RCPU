main:
    PUSH 1258
    MOV ret1, (0000)
    JMP sqrt
ret1:
    POP A
end:
    JMP end
sqrt:
    POP A
    JLT err
    SUB A, 2, 0
    JLT L1
    PUSH A
    RET
L1:
    MOV A, B
    RSHI B, 2
    PUSH A
    PUSH (0000)
    PUSH B
    MOV ret2, (0000)
    JMP sqrt
ret2:
    POP B
    POP (0000)
    POP A
    LSHI B, 1
    ADD B, 1, C
    MUL B, C, C
    SUB A, C, 0
    JLT L2
    ADD B, 1, C
    PUSH C
    RET
L2:
    PUSH B
    RET
err:
    JMP err
