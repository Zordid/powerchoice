DATA   SEGMENT WORD PUBLIC
DATA   ENDS

CODE   SEGMENT BYTE PUBLIC
       ASSUME CS:CODE,DS:DATA
       PUBLIC NewInt

NewInt PROC FAR
       JMP SHORT GO
ADDR   DD ?
COUNT  DB 1
GO:    CMP AX,4B00H          ; Exec-call ?
       JNE OK                ; No, go ahead ...
       CMP CS:[COUNT],1      ; First call ?
       JNE CHG               ; If not, change AL to interrupt function
       MOV CS:[COUNT],0      ; Indicate first time "used"
       JMP SHORT OK          ; One call allowed !
CHG:   MOV AL,0FFH           ; Change AL
OK:    JMP CS:[ADDR]
NewInt ENDP

CODE   ENDS
       END