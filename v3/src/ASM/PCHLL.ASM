; Power-Choice 3.10 low-level driver
; implements data exchange for Power-Choice system

IDEAL

true      EQU 1
false     EQU 0

; Macro DOS: calls a DOS-function
MACRO dos func
  mov ah, func
  int 21h
ENDM

; Macro LINK: links and interrupt handler and saves old vector
MACRO link int, oldintloc, newintloc
  mov al, int
  dos 35h
  mov [WORD PTR oldintloc], bx
  mov [WORD PTR oldintloc+2], es
  mov dx, offset newintloc
  mov al, int
  dos 25h
ENDM

MACRO pushm regs
  IRP r, <regs>
    push r
  ENDM
ENDM

MACRO popm regs
  IRP r, <regs>
    pop r
  ENDM
ENDM

;

SEGMENT code BYTE
  ASSUME cs:code, ds:code
  ORG 100h

begin:   jmp install

; Pascal interface
                                    ; Record
newint:    iret                     ;   IRET: Byte; 
id         DB 6,"PCH310"            ;   ID: String[6];
clock      DB 0                     ;   Clock: Byte;
scrsaver   DB false                 ;   ScrSaver,
waitforkey DB false                 ;   WaitforKey,
booted     DB true                  ;   Booted : Boolean;
password   DB 0                     ;   Password: String[15];
           DB 15 DUP (?)
minutes    DW 5*60*18               ;
                                    ; End;

old60	DD ?

end_tsr  EQU $               ; Resident part ends here

intromsg DB "Power-Choice Version 3.1",13,10
         DB "(C) Copyright by Olaf Gottschalk 1990-94",13,10,"$"
okmsg    DB "Low-level driver installed.",13,10,"$"
errormsg DB "Already installed.",7,13,10,"$"

install: mov dx, offset intromsg
         dos 9h
         mov al, 60h
         dos 35h
         mov di, bx
         inc di
         mov si, offset id
         mov cx, 7
         cld
         repe cmpsb
         jne go

         mov dx, offset errormsg
         dos 9h
exit:    mov ax, 4c01h
         int 21h

go:      mov dx, offset okmsg
         dos 9h
         cli
         link 60h, old60, newint
         sti
         mov ax, offset end_tsr
         add ax, 15
         mov cl, 4
         shr ax, cl
         mov dx, ax
         mov ax, 3100h
         int 21h

ENDS code
END begin
