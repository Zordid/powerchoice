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
         call askpwd
         mov [WORD LOW(request_header PTR di).rh_addr], offset init
         mov [WORD HIGH(request_header PTR di).rh_addr], cs
         mov ax, 100h
         jmp exit
ENDP init

maxlen EQU 15

PROC askpwd NEAR
         pushm <ds, di>
         push cs
         pop ds
         cmp [pwtable], 0
         je nopw
frage:   call getinput          ; get user's input
         mov si, offset input   ; ds:si points to input
         push ds
         pop es
         mov di, offset pwtable ; es:di points to table
         cmp al, [di]
         jne wrong
         ; lengths are equal, so compare rest
         inc di
         mov cx, ax
         cld
         repe cmpsb             ; compare strings
         je right
         ; try next password
wrong:   mov dx, offset wrongtxt
         mov ah, 9
         int 21h
         jmp frage
right:   mov dx, offset oktxt
         mov ah, 9
         int 21h
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
         cmp al, 'z'
         je @@z
         cmp al, 'Z'
         je @@Z_
         cmp al, 'y'
         je @@y
         cmp al, 'Y'
         je @@Y_
         jmp @@ok
@@z:     mov al, 'y'
         jmp @@ok
@@Z_:    mov al, 'Y'
         jmp @@ok
@@y:     mov al, 'z'
         jmp @@ok
@@Y_:    mov al, 'Z'
@@ok:    xor al, chiffre
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
wrongtxt DB 13, "  X", 13, 10, "$"
oktxt    DB 13, "OK...", 13, 10, 10, "$"

LABEL pwtable BYTE
pw       DB maxlen+1 DUP (0)

ENDS CODE
END
