; Power-Choice 3.00 low-level driver
; implements clock, sreen saver and data exchange for Power-Choice system
; requires EGA or VGA graphics card

IDEAL

true      EQU 1
false     EQU 0

; EGA/VGA definitions
ev_statc  EQU 03dah   ; Status register color
ev_statm  EQU 03bah   ;   "       "     monochrome
ev_attr   EQU 03c0h   ; Attribute controller

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
id         DB 6,"PCH301"            ;   ID: String[6];
clock      DB 0                     ;   Clock: Byte;
scrsaver   DB false                 ;   ScrSaver,
waitforkey DB false                 ;   WaitforKey,
booted     DB true                  ;   Booted,
minutes    DW 5*60*18               ;
                                    ; End;

; Clock Procedures

oldclock DD ?

chr1     DB ?
att1     DB 07H
chr2     DB ?
att2     DB 07H
chr3     DB ':'
att3     DB 07H
chr4     DB ?
att4     DB 07H
chr5     DB ?
att5     DB 07H
chr6     DB ':'
att6     DB 07H
chr7     DB ?
att7     DB 07H
chr8     DB ?
att8     DB 07H

drop     DB 0
tick     DB 1

PROC Videomode NEAR
         mov al, [es:0449h]
         cmp al, 3
         ja graphics
         mov di, 40h
         cmp al, 1
         jbe @@40x25
         add di, 50h
@@40x25: mov ax, 0b800h
         mov cx, 8
         clc
         ret
graphics:stc
         ret
ENDP Videomode

PROC ClockInt FAR
         sti
         pushm <ax, es, ds>
         mov ax, cs
         mov ds, ax
         xor ax, ax
         mov es, ax
         mov al, [es:0417h]
         and al, 0dh
         cmp al, 0dh
         je pressed
         mov [BYTE PTR drop], 0
         jmp ch1
pressed: cmp [BYTE PTR drop], 0
         jne ch1
         not [BYTE PTR drop]
         cmp [BYTE PTR clock], 0
         jne lch
         mov [BYTE PTR tick], 1
         jmp nt1
lch:     pushm <cx, di>
         call Videomode
         jc nt2
         push es
         mov es, ax
         mov ax, 0720h
         cld
         rep stosw
         pop es
nt2:     popm <di, cx>
nt1:     not [BYTE PTR clock]
ch1:     cmp [BYTE PTR clock], 0
         jne ch2
         jmp ex1
ch2:     dec [BYTE PTR tick]
         je ch3
         jmp ex1
ch3:     pushm <cx, di>
         call Videomode
         jnc set
         jmp ex2
set:     pushm <bx, dx, si, ax>
         mov [BYTE PTR tick], 2
         mov ax, [es:046ch]
         mov dx, [es:046eh]
         mov bx, 0fff0h
         div bx
         aam
         add ax, 3030h
         mov [chr1], ah
         mov [chr2], al
         mov ax, dx
         xor dx, dx
         mov bx, 0444h
         div bx
         aam
         add ax, 3030h
         mov [chr4], ah
         mov [chr5], al
         mov ax, dx
         mov bx, 0ah
         mul bx
         mov bl, 0b6h
         div bl
         aam
         add ax, 3030h
         mov [chr7], ah
         mov [chr8], al
         lea si, [chr1]
         pop es
         cld
         rep movsw
         popm <si, dx, bx>
ex2:     popm <di, cx>
ex1:     popm <ds, es, ax>
         jmp [cs:oldclock]
ENDP ClockInt

; Screen Saver Procedures

oldsaver DD ?
old09    DD ?
enabled  DB true             ; Screen on or off
event    DB false            ; Event flag
count    DW ?                ; Counter

; Keyboard interrupt
PROC New09 FAR
         push ax
         in al, 60h
         cmp al, 0d8h
         jne @1
         in al, 61h
         or al, 80h
         out 61h, al
         and al, 7fh
         out 61h, al
         mov al, 20h
         out 20h, al
         mov [cs:count], 5
         pop ax
         iret
@1:      mov [cs:event], true
         pop ax
         jmp [cs:old09]
ENDP

; Switches display off
PROC ScreenOff NEAR
         pushm <ax, dx>       ; Save registers
         cmp [enabled], false ; Already off ?
         je @@exit            ; Yes, then end.

         mov dx, ev_statc
         in al, dx
         mov dx, ev_statm
         in al, dx
         mov dx, ev_attr
         mov al, 0
         out dx, al

@@exit:  popm <dx, ax>
         mov [enabled], false
         ret
ENDP

PROC ScreenOn NEAR
         pushm <ax, dx>
         cmp [enabled], true
         je @@exit

         mov dx, ev_statc
         in al, dx
         mov dx, ev_statm
         in al, dx
         mov dx, ev_attr
         mov al, 0ffh
         out dx, al

@@exit:  popm <dx, ax>
         mov [enabled], true
         ret
ENDP

PROC SaverInt FAR
         pushm <ax, ds>
         mov ax, cs          ; Initialize data segment
         mov ds, ax
         mov ax, [minutes]   ; AX = Minutes
         cmp ax, 0           ; Screen saver installed ?
         je @@exit
         dec [count]         ; Decrease counter
         jnz l01             ; Is it not zero ?

         mov [count], ax     ; Switch screen off and reset counter
         cmp [ScrSaver], false ; Is screen saver active ?
         je l01              ; No, then end.
         call ScreenOff

l01:     cmp [event], false  ; Anything happened ?
         je @@exit           ; No, then end.

         mov [count], ax     ; Reset counter and flag, switch screen on
         mov [event], false
         call ScreenOn

@@exit:  popm <ds, ax>
         jmp [cs:oldsaver]   ; Back to old handler
ENDP SaverInt

end_tsr  EQU $               ; Resident part ends here

intromsg DB "Power-Choice Version 3.02",13,10
         DB "(C) Copyright by Olaf Gottschalk 1990-93",13,10,"$"
okmsg    DB "EGA/VGA Low-level driver installed.",13,10,"$"
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
         mov ax, [minutes]
         mov [count], ax
         cli
         link 60h, oldclock, newint
         link 1ch, oldclock, clockint
         link 1ch, oldsaver, saverint
         link 09h, old09, new09
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
