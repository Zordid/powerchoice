LINK     MACRO NO,OLDINT,NEWINT
         MOV AH,35H
         MOV AL,NO
         INT 21H
         MOV [OLDINT],BX
         MOV [OLDINT+2],ES
         MOV AH,25H
         MOV AL,NO
         MOV DX,OFFSET NEWINT
         INT 21H
LINK     ENDM

KEEP     MACRO ADDR
         MOV DX,OFFSET ADDR
         INT 27H
KEEP     ENDM
