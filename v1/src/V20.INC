PUSHA    MACRO
         DB 60H
         ENDM

POPA     MACRO
         DB 61H
         ENDM

PUSHI    MACRO VALUE
         IF (VALUE LE 127) AND (VALUE GE -128)
            DB 6AH,VALUE
         ELSE
            DB 68H
            DW VALUE
         ENDIF
         ENDM

REPC     MACRO
         DB 65H
         ENDM

REPNC    MACRO
         DB 64H
         ENDM

INSB     MACRO
         DB 6CH
         ENDM

INSW     MACRO
         DB 6DH
         ENDM

OUTSB    MACRO
         DB 6EH
         ENDM

OUTSW    MACRO
         DB 6FH
         ENDM

ADD4S    MACRO
         DB 0FH,20H
         ENDM

SUB4S    MACRO
         DB 0FH,22H
         ENDM

CMP4S    MACRO
         DB 0FH,26H
         ENDM

INS      MACRO OP1,OP2
         LOCAL O1,O2
         @GET_R8 OP1,O1
         @GET_R8 OP2,O2
         IF O2 EQ 8
            DB 0FH,39H,0C0H+O1,OP2
         ELSE
            DB 0FH,31H,0C0H+O1+8*O2
         ENDIF
         ENDM

EXT      MACRO OP1,OP2
         LOCAL O1,O2
         @GET_R8 OP1,O1
         @GET_R8 OP2,O2
         IF O2 EQ 8
            DB 0FH,3BH,0C0H+O1,OP2
         ELSE
            DB 0FH,33H,0C0H+O1+8*O2
         ENDIF
         ENDM

TEST1    MACRO OP1,OP2
         @BIT OP1,OP2,10H
         ENDM

NOT1     MACRO OP1,OP2
         @BIT OP1,OP2,16H
         ENDM

CLR1     MACRO OP1,OP2
         @BIT OP1,OP2,12H
         ENDM

SET1     MACRO OP1,OP2
         @BIT OP1,OP2,14H
         ENDM

@BIT     MACRO OP1,OP2,TR
         LOCAL O1
         @GET_R8 OP1,O1
         IFDIF <OP2>,<cl>
            IFDIF <OP2>,<CL>
               IF O1 NE 8
                  DB 0FH,TR+8,0C0H+O1,OP2
               ELSE
                  @GET_R16 OP1,O1
                  DB 0FH,TR+9,0C0H+O1,OP2
               ENDIF
               EXITM
            ENDIF
         ENDIF
         IF OL NE 8
            DB 0FH,TR,0C0H+O1
         ELSE
            @GET_R16 OP1,O1
            DB 0FH,TR+1,0C0H+O1
         ENDIF
         ENDM

SHLI     MACRO REG,IMM
         @SHIFT REG,IMM,0E0H
         ENDM

SHRI     MACRO REG,IMM
         @SHIFT REG,IMM,0E8H
         ENDM

SARI     MACRO REG,IMM
         @SHIFT REG,IMM,0F8H
         ENDM

ROLI     MACRO REG,IMM
         @SHIFT REG,IMM,0C0H
         ENDM

RORI     MACRO REG,IMM
         @SHIFT REG,IMM,0C8H
         ENDM

RCLI     MACRO REG,IMM
         @SHIFT REG,IMM,0D0H
         ENDM

RCRI     MACRO REG,IMM
         @SHIFT REG,IMM,0D8H
         ENDM

@SHIFT   MACRO REG,IMM,TR
         LOCAL R
         @GET_R8 REG,R
         IF R EQ 8
            @GET_R16 REG,R
            DB 0C1H,TR+R,IMM
         ELSE
            DB 0C0H,TR+R,IMM
         ENDIF
         ENDM

ROL4     MACRO REG
         LOCAL R
         @GET_R8 REG,R
         DB 0FH,28H,0C0H+R
         ENDM

ROR4     MACRO REG
         LOCAL R
         @GET_R8 REG,R
         DB 0FH,2AH,0C0H+R
         ENDM

IMULI    MACRO REG1,REG2,IMM
         LOCAL R1,R2
         @GET_R16 REG1,R1
         IFB <IMM>
            IF (REG2 GT 127) OR (REG2 LT -128)
               DB 69H,0C0H+9*R1
               DW REG2
            ELSE
               DB 6BH,0C0H+9*R1,REG2
            ENDIF
            EXITM
         ELSE
            @GET_R16 REG2,R2
            IF (IMM GT 127) OR (IMM LT -128)
               DB 69H,0C0H+8*R1+R2
               DW IMM
            ELSE
               DB 6BH,0C0H+8*R1+R2,IMM
            ENDIF
         ENDIF
         ENDM

ENTER    MACRO IMM16,IMM8
         DB 0C8H
         DW IMM16
         DB IMM8
         ENDM

LEAVE    MACRO
         DB 0C9H
         ENDM

BRKEM    MACRO IMM8
         DB 0FH,0FFH,IMM8
         ENDM

RETEM    MACRO
         DB 0EDH,0FDH
         ENDM

CALLN    MACRO IMM8
         DB 0EDH,0EDH,IMM8
         ENDM

@GET_R8  MACRO REG,DEST
         DEST=0
         IRP R,<AL,CL,DL,BL,AH,CH,DH,BH>
            IFIDN <REG>,<R>
               EXITM
            ENDIF
            DEST=DEST+1
         ENDM
         IF DEST EQ 8
            DEST=0
            IRP R,<al,cl,dl,bl,ah,ch,dh,bh>
               IFIDN <REG>,<R>
                  EXITM
               ENDIF
               DEST=DEST+1
            ENDM
         ENDIF
         ENDM

@GET_R16 MACRO REG,DEST
         DEST=0
         IRP R,<AX,CX,DX,BX,SP,BP,SI,DI>
            IFIDN <REG>,<R>
               EXITM
            ENDIF
            DEST=DEST+1
         ENDM
         IF DEST EQ 8
            DEST=0
            IRP R,<ax,cx,dx,bx,sp,bp,si,di>
               IFIDN <REG>,<R>
                  EXITM
               ENDIF
               DEST=DEST+1
            ENDM
         ENDIF
         ENDM

TEST_V20 MACRO
         LOCAL IS_286,IS_V20,ERR_TXT
         PUSHF
         POP CX
         ROL CX,1
         JNC IS_286
         MOV CX,1
         REPC
         CMPSB
         JCXZ IS_V20
IS_286:  PUSH CS
         POP DS
         MOV AH,9
         MOV DX,OFFSET ERR_TXT
         INT 21H
         MOV AX,4C08H
         INT 21H
ERR_TXT  DB 13,10,"Programm läuft nur auf V20-CPU !",7,13,10,"$"
IS_V20:
         ENDM