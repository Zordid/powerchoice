; Power-Choice 3.00 password detection routine
; usage: DEVICE=PCHPW.SYS

IDEAL

chiffre  EQU 7fh
true     EQU 1
false    EQU 0
ev_statc EQU 03dah
ev_statm EQU 03bah
ev_attr  EQU 03c0h

; Macros

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

; Definitions

STRUC request_header
  rh_len  DB ?
  rh_unit DB ?
  rh_cmd  DB ?
  rh_stat DW ?
  rh_res  DB 8 DUP(?)
  rh_desc DB ?
  rh_addr DD ?
  rh_cnt  DW ?
ENDS request_header

; Device header

SEGMENT CODE
        ASSUME CS:CODE, DS:CODE, ES:CODE
        ORG 0

header DD -1
       DW 8000h
       DW strategy
       DW interrupt
       DB "PCH$300 "
       DW offset pwtable

request DW ?, ?

; Routines

PROC dataint FAR
         iret
password DB 0
ENDP

PROC strategy FAR
         mov [cs:request], bx
         mov [cs:request+2], es
         ret
ENDP strategy

PROC interrupt FAR
         cld
         pushm <ax, bx, cx, dx, ds, es, si, di>
         pushf
         lds di, [DWORD PTR cs:request]
         mov al, [(request_header PTR di).rh_cmd]
         cmp al, 0
         je init
         mov al, 3
         mov ah, 81h
exit:    mov [(request_header PTR di).rh_stat], ax
         popf
         popm <di, si, es, ds, dx, cx, bx, ax>
         ret
ENDP interrupt

; End of "resident" part

PROC init NEAR
         push es
         xor ax, ax
         mov es, ax
         mov [WORD PTR es:60h*4], offset dataint
         mov [WORD PTR es:60h*4+2], cs
         pop es
         call askpwd
         mov [WORD LOW(request_header PTR di).rh_addr], offset init
         mov [WORD HIGH(request_header PTR di).rh_addr], cs
         mov ax, 100h
         jmp exit
ENDP init

maxlen EQU 30
maxpw  EQU 10

PROC askpwd NEAR
         pushm <ds, di>
         push cs
         pop ds
         cmp [pwtable], 0
         je nopw
frage:   call getinput          ; get user's input
         mov cx, maxpw+1        ; cx equals number of passwords
         mov si, offset input   ; ds:si points to input
         push ds
         pop es
         mov di, offset pwtable ; es:di points to table
         mov bx, 1
nextpw:  cmp al, [di]
         jne next
         ; lengths are equal, so compare rest
         pushm <cx, si, di>
         mov cx, ax
         inc di
         cld
         repe cmpsb             ; compare strings
         popm <di, si, cx>
         je right
         ; try next password
next:    mov dl, [BYTE PTR di]
         xor dh, dh
         add di, dx
         inc di
         inc bx
         loop nextpw
         mov dx, offset wrong
         mov ah, 9
         int 21h
         jmp frage
right:   mov dx, offset ok
         mov ah, 9
         int 21h
         dec bl
         mov [password], bl
nopw:    popm <di, ds>
         ret
ENDP askpwd

PROC getinput NEAR
         mov dx, offset key
         mov ah, 9
         int 21h
clr_buf: mov ah, 1
         int 16h
         jz empty
         xor ax, ax
         int 16h
         jmp clr_buf
empty:   xor cx, cx
         mov bx, offset input
getkey:  xor ax, ax
         int 16h
         cmp al, 0dh
         je return
         cmp cx, maxlen
         je full
         xor al, chiffre
         mov [bx], al
         inc bx
         inc cx
full:    mov al, 32
         mov ah, 14
         int 10h
         jmp getkey
return:  mov ax, cx
         ret
ENDP getinput

input    DB maxlen+1 DUP (0)
key      DB "o─╖", 13, 10, "$"
wrong    DB 13, "  X", 13, 10, "$"
ok       DB 13, "OK...", 13, 10, 10, "$"

LABEL pwtable BYTE
pw0      DB 0
pws      DB maxpw DUP (0)

ENDS CODE
END
