TRUE      EQU 1
FALSE     EQU 0

HERC      EQU 1       ; Hercules flag
CGAMDA    EQU 2       ; CGA oder MDA flag
; Hercules definitions
HINDEX    EQU 03B4H   ; Index register
HSTATUS   EQU 03BAH   ; Status register
HLP_SET   EQU 03B9H   ; Light pen register
TXT_LIMIT EQU 0B8DH   ; Limit for text display
TXT_VERT  EQU 25      ; Vertical display for text
GRA_VERT  EQU 87      ;    "        "     "  graphics
; EGA/VGA definitions
EV_STATC  EQU 03DAH   ; Status register color
EV_STATM  EQU 03BAH   ;   "       "     monochrome
EV_ATTR   EQU 03C0H   ; Attribute controller

; Macro DOS: calls a DOS-function
DOS      MACRO FUNC
         MOV AH,FUNC
         INT 21H
         ENDM

; Macro LINK: links and interrupt handler and saves old vector
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
         ASSUME CS:CODE,DS:CODE,ES:CODE,DS:CODE
         ORG 256

BEG:     JMP INSTALL

OLDCLOCK DD ?
OLDINT   DD ?

; Pascal interface
                                  ; Record
NEWINT:  JMP CS:[OLDINT]          ;   JMP   : String[4];
ID       DB 6,"PCH300"            ;   ID    : String[6];
MINUTES  DW 5*60*18               ;   MSave : Word;
MACTIVE  DB TRUE                  ;   MActive : Boolean;
PASSWORD DB 1                     ;   PW    : Byte;
EDITON   DB TRUE                  ;   EditOn: Boolean;
OPTON    DB TRUE                  ;   OptionsOn: Boolean;
DOSON    DB TRUE                  ;   DosOn: Boolean;
BOOTED   DB TRUE                  ;   Booted: Boolean;
CLOCK    DB 0FFH                  ;   Clock : Byte;
WAIT_    DB 0                     ;   Wait  : Byte;
VCARD    DB 3
                                  ; End;

; Clock Procedures

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

CLOCK_   PROC FAR
         STI
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
CLOCK_   ENDP

; Screen Saver Procedures

OLDSAVER DD ?
OLD09    DD ?
OLDMOUSE DD ?
ENABLED  DB TRUE             ; Screen on or off
EVENT    DB FALSE            ; Event flag
COUNT    DW ?                ; Counter
TABLE    DB 2CH,28H,2DH,29H  ; Table for control register values
         DB 2AH,2EH,1EH,29H  ; (CGA and MDA cards)

; Keyboard interrupt
NEW09    PROC FAR
         MOV CS:[EVENT],TRUE
         JMP CS:[OLD09]
NEW09    ENDP

GETMOD   PROC NEAR
         PUSH BX
         MOV AH,0FH
         INT 10H
         MOV DX,03D8H
         MOV BL,AL
         XOR BH,BH
         MOV AL,[TABLE+BX]
         POP BX
         RET
GETMOD   ENDP

; Switches display off
SCROFF   PROC NEAR
         PUSH AX              ; Save registers
         PUSH DX
         CMP [ENABLED],FALSE  ; Already off ?
         JE SCRF_END          ; Yes, then end.

         MOV AL,[VCARD]
         CMP AL, 0            ; No video card detected ?
         JE SCRF_END

         CMP AL,HERC          ; Is it Hercules card ?
         JNE SCRF1

         MOV AL,6
         MOV DX,HINDEX
         OUT DX,AL
         INC DX
         MOV AL,0
         OUT DX,AL
         JMP SCRF_END

SCRF1:   CMP AL,CGAMDA
         JNE SCRF2
         CALL GETMOD
         AND AL,0F7H
         OUT DX,AL
         JMP SCRF_END

SCRF2:   MOV DX,EV_STATC
         IN AL,DX
         MOV DX,EV_STATM
         IN AL,DX
         MOV DX,EV_ATTR
         MOV AL,0
         OUT DX,AL

SCRF_END:POP DX
         POP AX
         MOV [ENABLED],FALSE
         RET
SCROFF   ENDP

SCRON    PROC NEAR
         PUSH AX
         PUSH DX
         CMP [ENABLED],TRUE
         JE SCRO_END

         MOV AL,[VCARD]
         CMP AL, 0
         JE SCRO_END

         CMP AL,HERC
         JNE SCRO1

         PUSH BX
         XOR AX,AX
         MOV DX,HSTATUS
VR1:     IN AL,DX
         TEST AL,10000000B
         JZ VR1
VR2:     IN AL,DX
         TEST AL,10000000B
         JNZ VR2
         XOR AL,AL
         INC DX
         OUT DX,AL
         MOV DX,HLP_SET
         OUT DX,AL
         MOV DX,HINDEX
         MOV AL,16
         OUT DX,AL
         INC DX
         IN AL,DX
         MOV BH,AL
         DEC DX
         MOV AL,17
         OUT DX,AL
         INC DX
         IN AL,DX
         MOV BL,AL
         MOV AH,TXT_VERT
         CMP BX,TXT_LIMIT
         JB TEXTMODE
         MOV AH,GRA_VERT
TEXTMODE:MOV AL,6
         DEC DX
         OUT DX,AL
         INC DX
         MOV AL,AH
         OUT DX,AL
         POP BX
         JMP SCRO_END

SCRO1:   CMP AL,CGAMDA
         JNE SCRO2
         CALL GETMOD
         OUT DX,AL
         JMP SCRO_END

SCRO2:   MOV DX,EV_STATC
         IN AL,DX
         MOV DX,EV_STATM
         IN AL,DX
         MOV DX,EV_ATTR
         MOV AL,0FFH
         OUT DX,AL

SCRO_END:POP DX
         POP AX
         MOV [ENABLED],TRUE
         RET
SCRON    ENDP

SAVER    PROC FAR
         PUSH AX
         PUSH DS
         MOV AX,CS           ; Initialize data segment
         MOV DS,AX
         MOV AX,[MINUTES]    ; AX = Minutes
         CMP AX,0            ; Screen saver installed ?
         JE END1C
         DEC [COUNT]         ; Decrease counter
         JNZ L01             ; Is it not zero ?

         MOV [COUNT],AX      ; Switch screen off and reset counter
         CMP [MACTIVE],FALSE ; Is screen saver active ?
         JE L01              ; No, then end.
         CALL SCROFF

L01:     CMP [EVENT],FALSE   ; Anything happened ?
         JE END1C            ; No, then end.

         MOV [COUNT],AX      ; Reset counter and flag, switch screen on
         MOV [EVENT],FALSE
         CALL SCRON

END1C:   POP DS
         POP AX
         JMP CS:[OLDSAVER]   ; Back to old handler
SAVER    ENDP

END_TSR  EQU $               ; Resident part ends here

INTRO    DB "Power-Choice Beta-Version 3.00",13,10
         DB "(C) Copyright by Olaf Gottschalk 1991",13,10,"$"
OK       DB "Low-level driver installed.",13,10,"$"
ERROR    DB "Already installed.",7,13,10,"$"

INSTALL: MOV DX,OFFSET INTRO
         DOS 9H
         MOV AL,61H
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
EXIT:    MOV AX,4C01H
         INT 21H

GO:      MOV DX,OFFSET OK
         DOS 9H
         MOV AX,[MINUTES]
         MOV [COUNT],AX
         CLI
         LINK 61H,OLDINT,NEWINT
         LINK 1CH,OLDCLOCK,CLOCK_
         LINK 1CH,OLDSAVER,SAVER
         LINK 09H,OLD09,NEW09
         STI
         MOV AX,OFFSET END_TSR
         ADD AX,15
         MOV CL,4
         SHR AX,CL
         MOV DX,AX
         MOV AX,3100H
         INT 21H

CODE     ENDS

         END BEG
