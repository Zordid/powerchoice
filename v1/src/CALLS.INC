EDITABS  PROC
         PUSHF
         PUSH AX
         PUSH BX
         PUSH DX
         PUSH DI
         PUSH SI
         MOV BH,CH
         XOR CH,CH
         MOV SI,10
         MOV DI,DX
         ADD DI,CX
         DEC DI
         JMP STRT
DIVIDE:  OR AX,AX
         JZ DEZ2
STRT:    XOR DX,DX
         DIV SI
         OR DL,30H
         MOV BYTE PTR ES:[DI],DL
         DEC DI
         LOOP DIVIDE
DEZ1:    POP SI
         POP DI
         POP DX
         POP BX
         POP AX
         POPF
         RET
DEZ2:    MOV AL,BH
         STD
         REP STOSB
         JMP DEZ1
EDITABS  ENDP

SHOWMSG  PROC
         PUSH AX
         PUSH BX
         PUSH BP
         PUSH DI
         PUSH SI
         PUSH DS
         MOV AX,CS
         MOV DS,AX
         MOV SI,DX
SHOWLP:  LODSB
         CMP AL,"$"
         JE SHOWEND
         MOV AH,0EH
         INT 10H
         JMP SHOWLP
SHOWEND: POP DS
         POP SI
         POP DI
         POP BP
         POP BX
         POP AX
         RET
SHOWMSG  ENDP

DISPLMSG PROC
         PUSH AX
         PUSH BX
         PUSH DX
         MOV BX,DX
DISPLOOP:MOV DL,CS:[BX]
         CMP DL,"$"
         JE DISPLEND
         CALL DISPLDL
         INC BX
         JMP DISPLOOP
DISPLEND:POP DX
         POP BX
         POP AX
         RET
DISPLMSG ENDP

DISPLDL  PROC
         PUSH AX
         PUSH DX
         PUSH SI
         PUSH DI
         PUSH BP
         MOV AL,DL
         MOV AH,0
         MOV DX,0
         INT 17H
         TEST AH,1
         JNZ PRT_ERR
PRT_END: POP BP
         POP DI
         POP SI
         POP DX
         POP AX
         RET
PRT_FEH  DB 10,13,"Bitte Drucker überprüfen !",7,"$"
PRT_ERR: PUSH DS
         MOV DX,CS
         MOV DS,DX
         MOV DX,OFFSET PRT_FEH
         CALL SHOWMSG
         POP DS
         JMP PRT_END
DISPLDL  ENDP

BINABS   PROC
         PUSHF
         PUSH AX
         PUSH CX
         XOR AH,AH
         MOV CH,"0"
         MOV CL,2
         CALL EDITABS
         POP CX
         POP AX
         POPF
         RET
BINABS   ENDP

BINHEXA  PROC
         PUSH CX
         PUSH AX
         MOV CL,4
         SHR AL,CL
         CALL TRANSLAT
         MOV CH,AL
         POP AX
         AND AL,0FH
         CALL TRANSLAT
         MOV AH,CH
         POP CX
         RET
BINHEXA  ENDP

TRANSLAT PROC
         ADD AL,090H
         DAA
         ADC AL,040H
         DAA
         RET
TRANSLAT ENDP

BIN2ABS  PROC
         PUSHF
         PUSH AX
         PUSH CX
         MOV CH,"0"
         MOV CL,4
         CALL EDITABS
         POP CX
         POP AX
         POPF
         RET
BIN2ABS  ENDP

DISPLAX  PROC
         PUSH DX
         PUSH AX
         MOV DH,AL
         XCHG AH,AL
         CALL BINHEXA
         MOV DL,AH
         CALL DISPLDL
         MOV DL,AL
         CALL DISPLDL
         MOV AL,DH
         CALL BINHEXA
         MOV DL,AH
         CALL DISPLDL
         MOV DL,AL
         CALL DISPLDL
         POP AX
         POP DX
         RET
DISPLAX  ENDP

DISPLMEM PROC
         CALL DISPLMSG
         MOV DX,OFFSET DISPLO
         CALL DISPLMSG
         RET
DISPLO   DB 13,10,"          0.1.2.3.4."
         DB "5.6.7. 8.9.A.B.C.D.E.F.  01"
         DB "23456789ABCDEF$"
DISPLMEM ENDP

READECHO PROC
         MOV AH,0
         INT 16H
         PUSH SI
         PUSH DI
         PUSH BP
         PUSH CX
         PUSH BX
         PUSH AX
         MOV AH,0FH
         INT 10H
         POP AX
         PUSH AX
         MOV AH,09H
         MOV BL,7
         MOV CX,1
         INT 10H
         POP AX
         POP BX
         POP CX
         POP BP
         POP DI
         POP SI
         RET
READECHO ENDP

MEMORY   PROC
         JMP MEMO0
REPSW    DB 0
MEMO12   DB 13,10,"$"
MEMO13   DB " *$"
MEMO14   DB 0DH,0AH,"          ..."
         DB "              ...$"
MEMO0:   PUSH SI
         PUSH DS
         PUSH CX
         PUSH AX
         PUSHF
         CLD
         MOV CS:REPSW,30H
         AND SI,0FFF0H
MEMO1:   CMP CS:REPSW,30H
         JE MEMO4
         PUSH CX
         PUSH DI
         PUSH ES
         PUSH SI
         MOV DI,DS
         DEC DI
         MOV ES,DI
         MOV CX,8
         MOV DI,SI
         REPZ CMPSW
         JNZ MEMO2
         CMP CS:REPSW,31H
         JNE MEMO15
         MOV DX,OFFSET MEMO14
         CALL DISPLMSG
         MOV CS:REPSW,32H
MEMO15:  POP ES
         POP ES
         POP DI
         POP CX
         JMP MEMO9
MEMO16:  JMP MEMO1
MEMO2:   POP SI
         POP ES
         POP DI
         POP CX
MEMO4:   PUSH CX
         MOV CX,8
         MOV CS:REPSW,31H
         PUSH SI
         MOV DX,OFFSET MEMO12
         CALL DISPLMSG
         MOV AX,DS
         CALL DISPLAX
         MOV DL,":"
         CALL DISPLDL
         MOV AX,SI
         CALL DISPLAX
MEMO3:   TEST CX,0003H
         JNZ MEMO6
         MOV DL," "
         CALL DISPLDL
MEMO6:   LODSW
         XCHG AH,AL
         CALL DISPLAX
         LOOP MEMO3
         POP SI
         MOV DX,OFFSET MEMO13
         CALL DISPLMSG
         MOV CX,16
MEMO7:   LODSB
         MOV DL,"."
         CMP AL,7FH
         JNC MEMO8
         CMP AL," "
         JB MEMO8
         XCHG AL,DL
MEMO8:   CALL DISPLDL
         LOOP MEMO7
         MOV DL,"*"
         CALL DISPLDL
         POP CX
MEMO9:   OR SI,SI
         JNZ MEMO10
         MOV AX,DS
         ADD AX,1000H
         MOV DS,AX
MEMO10:  CMP CX,2
         JNE MEMO11
         MOV CS:REPSW,30H
MEMO11:  LOOP MEMO16
         POPF
         POP AX
         POP CX
         POP DS
         POP SI
         RET
MEMORY   ENDP

SPLITMEM PROC
         PUSH SI
         PUSH AX
         PUSH CX
         PUSH DS
         MOV AX,CS
         SHL AX,1
         SHL AX,1
         SHL AX,1
         SUB SI,AX
         JNC SPLIT0
         MOV AX,DS
         SUB AX,1000H
         MOV DS,AX
SPLIT0:  AND SI,0FFF0H
         CALL MEMORY
         POP DS
         POP CX
         POP AX
         POP SI
         RET
SPLITMEM ENDP
