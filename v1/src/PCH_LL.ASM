;

VID      EQU 10H
INICOUNT EQU 3*60*18
CGAPORT  EQU 03D8H
MGAPORT  EQU 03B8H
MGAMODE  EQU 7
TRUE     EQU 1
FALSE    EQU 0

KEEP     MACRO ADDR
         MOV DX,OFFSET ADDR
         INT 27H
         ENDM

DOS      MACRO FUNC
         MOV AH,FUNC
         INT 21H
         ENDM

LINK     MACRO INT,OLDINTLOC,NEWINTLOC
         MOV AL,INT
         DOS 35H
         MOV WORD PTR OLDINTLOC,BX
         MOV WORD PTR OLDINTLOC+2,ES
         MOV DX,OFFSET NEWINTLOC
         MOV AL,INT
         DOS 25H
         ENDM

;

CODE     SEGMENT BYTE
         ASSUME CS:CODE,DS:CODE
         ORG 0100H

BEG:     JMP INSTALL

OLDSAVER DD ?
OLDCLOCK DD ?
OLD60    DD ?
OLD09    DD ?
OLD0C    DD ?
OLD0B    DD ?

ENABLED  DB TRUE
EVENT    DB FALSE
COUNT    DW INICOUNT
TABLE    DB 2CH,28H,2DH,29H
         DB 2AH,2EH,1EH,29H

CHR1     DB ?
ATT1     DB 07H
CHR2     DB ?
ATT2     DB 07H
CHR3     DB ':'
ATT3     DB 07H
CHR4     DB ?
ATT4     DB 07H
CHR5     DB ?
ATT5     DB 07H
CHR6     DB ':'
ATT6     DB 07H
CHR7     DB ?
ATT7     DB 07H
CHR8     DB ?
ATT8     DB 07H
DROP     DB 00H
TICK     DB 01H

                                  ; Record
NEW60:   JMP CS:[OLD60]           ;   JMP   : String[4];
ID       DB 6,"      "            ;   ID    : String[6];
MSAVE    DB FALSE                 ;   MSave : Byte;
VIDEO    DB 0                     ;   Video : Byte;
PATH     DB 0                     ;   Path  : String[20];
         DB 30 DUP(0)
PRG      DB 1                     ;   Item  : Byte;
GRP      DB 1                     ;   Group : Byte;
PASSWORD DB 0                     ;   PWok  : Byte;
STATUS   DB 0                     ;   Status: Byte;
CLOCK    DB 0FFH                  ;   Clock : Byte;
WAIT_    DB 0                     ;   Wait  : Byte;
                                  ; End;
;

NEW09   PROC FAR
        MOV CS:[EVENT],TRUE
        JMP CS:[OLD09]
NEW09   ENDP

NEW0B   PROC FAR
        MOV CS:[EVENT],TRUE
        JMP CS:[OLD0B]
NEW0B   ENDP

NEW0C   PROC FAR
        MOV CS:[EVENT],TRUE
        JMP CS:[OLD0C]
NEW0C   ENDP

;

GETMOD  PROC NEAR
        MOV AH,0FH
        INT VID
        MOV DX,CGAPORT
        CMP AL,MGAMODE
        JNE GETMOD1
        MOV DX,MGAPORT
GETMOD1:MOV BL,AL
        XOR BH,BH
        MOV AL,CS:[TABLE+BX]
        RET
GETMOD  ENDP

;

VDAT     PROC NEAR
         MOV AL,ES:[0449H]
         CMP AL,07H
         JNZ FRB
         MOV AX,0B000H
         JMP BRT
FRB:     CMP AL,03H
         JA GRF
         CMP AL,01H
         MOV AX,0B800H
         JZ SML
BRT:     MOV DI,0090H
         JMP ZUW
SML:     MOV DI,0040H
ZUW:     MOV CX,0008H
         CLC
         RET
GRF:     STC
         RET
VDAT     ENDP

CLOCK_:  STI
         PUSH AX
         PUSH ES
         PUSH DS
         MOV AX,CS
         MOV DS,AX
         XOR AX,AX
         MOV ES,AX
         MOV AL,ES:[0417H]
         AND AL,0DH
         CMP AL,0DH
         JZ GED
         MOV BYTE PTR DROP,00H
         JMP CH1
GED:     CMP BYTE PTR DROP,00H
         JNZ CH1
         NOT BYTE PTR DROP
         CMP BYTE PTR CLOCK,00H
         JNZ LCH
         MOV BYTE PTR TICK,01H
         JMP NT1
LCH:     PUSH CX
         PUSH DI
         CALL VDAT
         JC NT2
         PUSH ES
         MOV ES,AX
         MOV AX,0720H
         CLD
         REPZ STOSW
         POP ES
NT2:     POP DI
         POP CX
NT1:     NOT BYTE PTR CLOCK
CH1:     CMP BYTE PTR CLOCK,00H
         JNZ CH2
         JMP EX1
CH2:     DEC BYTE PTR TICK
         JZ CH3
         JMP EX1
CH3:     PUSH CX
         PUSH DI
         CALL VDAT
         JNC SET
         JMP EX2
SET:     PUSH BX
         PUSH DX
         PUSH SI
         PUSH AX
         MOV BYTE PTR TICK,02H
         MOV AX,ES:[046CH]
         MOV DX,ES:[046EH]
         MOV BX,0FFF0H
         DIV BX
         AAM
         ADD AX,3030H
         MOV CHR1,AH
         MOV CHR2,AL
         MOV AX,DX
         XOR DX,DX
         MOV BX,0444H
         DIV BX
         AAM
         ADD AX,3030H
         MOV CHR4,AH
         MOV CHR5,AL
         MOV AX,DX
         MOV BX,000AH
         MUL BX
         MOV BL,0B6H
         DIV BL
         AAM
         ADD AX,3030H
         MOV CHR7,AH
         MOV CHR8,AL
         LEA SI,CHR1
         POP ES
         CLD
         REPZ MOVSW
         POP SI
         POP DX
         POP BX
EX2:     POP DI
         POP CX
EX1:     POP DS
         POP ES
         POP AX
         JMP CS:[OLDCLOCK]

SAVER    PROC FAR
         PUSH AX
         PUSH BX
         PUSH DX
         DEC CS:[COUNT]
         JNE L01
         MOV CS:[COUNT],INICOUNT
         MOV CS:[ENABLED],FALSE
         CALL GETMOD
         AND AL,0F7H
         OUT DX,AL
L01:     TEST CS:[EVENT],TRUE
         JE END1C
         MOV CS:[COUNT],INICOUNT
         MOV CS:[EVENT],FALSE
         TEST CS:[ENABLED],TRUE
         JNE END1C
         MOV CS:[ENABLED],TRUE
         CALL GETMOD
         OUT DX,AL
END1C:   POP DX
         POP BX
         POP AX
         JMP CS:[OLDSAVER]
SAVER    ENDP

END_TSR  EQU $

INTRO    DB "Power-Choice Version 1.0e",13,10
         DB "(C) 1990 Softwhere Associates",13,10,"$"
OK       DB "Low-level driver installed.",13,10,"$"
ERROR    DB "Already installed.",7,13,10,"$"

INSTALL: MOV DX,OFFSET INTRO
         DOS 9H
         MOV AL,60H
         DOS 35H
         MOV CL,ES:[ID]
         XOR CH,CH
         MOV BH,CH
L1:      MOV DI,CX
         MOV BL,BYTE PTR ES:[ID+DI]
         CMP BL,BYTE PTR CS:[ID+DI]
         JNE GO
         LOOP L1

         MOV DX,OFFSET ERROR
         DOS 9H
         RET

GO:      CLI
         LINK 60H,OLD60,NEW60
         LINK 1CH,OLDCLOCK,CLOCK_
         CMP MSAVE,FALSE
         JE NOSAVE
         LINK 1CH,OLDSAVER,SAVER
         LINK 09H,OLD09,NEW09
         LINK 0BH,OLD0B,NEW0B
         LINK 0CH,OLD0C,NEW0C
NOSAVE:  STI
         MOV DX,OFFSET OK
         DOS 9H
         KEEP END_TSR

CODE     ENDS
         END BEG
