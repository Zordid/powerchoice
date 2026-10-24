; SCRDUMP.COM - resident text-screen dumper for DOSBox screenshots.
; On install writes FONT.BIN (8x16 ROM font, 4096 bytes). Then, every RATE
; timer ticks (default 18, about once per second; nasm -DRATE=4 for
; recordings), writes Snnn.BIN = [cols, rows, mode] + rows*cols*2 bytes of
; text video memory, whenever DOS is not busy. Keystrokes from KEYS.BIN
; (see keys.py) are fed into the BIOS keyboard buffer at their set times.
%ifndef RATE
%define RATE 18
%endif
        org 100h
start:  jmp install

old8    dd 0
indos   dd 0
ticks   db 0
busy    db 0
fname   db 'C:\S\S000.BIN',0
hdr     db 0,0,0
keyptr  dw keys
keyend  dw keys
keywait dw 0
keysnm  db 'C:\S\KEYS.BIN',0

int8:   pushf
        call far [cs:old8]
        push ax
        push bx
        push si
        push es
        mov si,[cs:keyptr]
        cmp si,[cs:keyend]
        jae .nokey
        dec word [cs:keywait]
        jnz .nokey
        mov ax,[cs:si]          ; key word (scan:ascii)
        add si,4
        mov [cs:keyptr],si
        mov bx,[cs:si+2]        ; delay before the next key
        mov [cs:keywait],bx
        mov bx,40h
        mov es,bx
        mov bx,[es:1Ch]         ; tail
        mov si,bx
        add bx,2
        cmp bx,[es:82h]
        jb .noWrap
        mov bx,[es:80h]
.noWrap:
        cmp bx,[es:1Ah]         ; buffer full?
        je .nokey
        mov [es:si],ax
        mov [es:1Ch],bx
.nokey: pop es
        pop si
        pop bx
        pop ax
        cmp byte [cs:busy],0
        jne .ret
        inc byte [cs:ticks]
        cmp byte [cs:ticks],RATE
        jb .ret
        push es
        push bx
        les bx,[cs:indos]
        cmp byte [es:bx],0
        pop bx
        pop es
        jne .ret
        mov byte [cs:ticks],0
        mov byte [cs:busy],1
        sti
        push ax
        push bx
        push cx
        push dx
        push si
        push ds
        push es
        push cs
        pop ds
        xor ax,ax
        mov es,ax
        mov al,[es:44Ah]        ; columns
        mov [hdr],al
        mov al,[es:484h]        ; rows-1
        inc al
        mov [hdr+1],al
        mov al,[es:449h]        ; video mode
        mov [hdr+2],al
        cmp al,3
        ja .done                ; text modes 0-3 only
        mov ah,3Ch              ; create file
        xor cx,cx
        mov dx,fname
        int 21h
        jc .done
        mov bx,ax
        mov ah,40h
        mov cx,3
        mov dx,hdr
        int 21h
        mov al,[hdr]
        mul byte [hdr+1]
        shl ax,1
        mov cx,ax
        mov ax,0B800h
        mov ds,ax
        xor dx,dx
        mov ah,40h
        int 21h
        push cs
        pop ds
        mov ah,3Eh
        int 21h
        ; increment the 3-digit counter in fname
        mov si,fname+8
.inc:   inc byte [si]
        cmp byte [si],'9'
        jbe .done
        mov byte [si],'0'
        dec si
        cmp si,fname+5
        ja .inc
.done:  pop es
        pop ds
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        mov byte [cs:busy],0
.ret:   iret

keys    times 4096 db 0
fontnm  db 'C:\S\FONT.BIN',0

install:
        push bp
        mov ax,1130h            ; get 8x16 font pointer -> ES:BP
        mov bh,6
        int 10h
        mov si,bp
        pop bp
        push es
        mov ah,3Ch
        xor cx,cx
        mov dx,fontnm
        int 21h
        pop ds
        jc .nofont
        mov bx,ax
        mov dx,si
        mov cx,4096
        mov ah,40h
        int 21h
        mov ah,3Eh
        int 21h
.nofont:
        push cs
        pop ds
        mov ax,3D00h
        mov dx,keysnm
        int 21h
        jc .nokeys
        mov bx,ax
        mov ah,3Fh
        mov cx,4096
        mov dx,keys
        int 21h
        jc .close
        add ax,keys
        mov [keyend],ax
        mov ax,[keys+2]
        mov [keywait],ax
.close: mov ah,3Eh
        int 21h
.nokeys:
        mov ah,34h
        int 21h
        mov [indos],bx
        mov [indos+2],es
        mov ax,3508h
        int 21h
        mov [old8],bx
        mov [old8+2],es
        mov ax,2508h
        mov dx,int8
        int 21h
        mov dx,install
        add dx,15
        shr dx,4
        mov ax,3100h
        int 21h
