; STANDIN.COM - a stand-in for the programs in the browser demo's menus.
; It takes its name from its own file name (WP.COM shows "WordPerfect 5.1"),
; explains that it is not the real program, and returns on any key. Row 0
; stays empty for the clock that Power-Choice's resident driver draws.
;
;   nasm -f bin -DV1 -o STANDIN.COM standin.asm   text for Power-Choice 1.0e
;   nasm -f bin      -o STANDIN.COM standin.asm   text for Power-Choice 3.1
        org 100h

BACK    equ 17h                 ; grey on blue
FRAME   equ 1Fh                 ; white on blue
TITLE   equ 1Eh                 ; yellow on blue
TOP     equ 4
LEFT    equ 9
WIDTH   equ 62
HEIGHT  equ 17

start:  mov ax,0B800h
        mov es,ax
        cld
        mov ah,1                ; hide the cursor
        mov cx,2000h
        int 10h
        ; row 0 black, for the clock; the rest blue
        xor di,di
        mov ax,0700h | ' '
        mov cx,80
        rep stosw
        mov ax,BACK << 8 | ' '
        mov cx,24*80
        rep stosw
        ; window frame
        mov bx,TOP
        mov dl,0DAh
        mov dh,0BFh
        mov al,0C4h
        call hline
        mov cx,HEIGHT-2
.rows:  inc bx
        mov dl,0B3h
        mov dh,0B3h
        mov al,' '
        call hline
        loop .rows
        inc bx
        mov dl,0C0h
        mov dh,0D9h
        mov al,0C4h
        call hline
        mov bx,TOP+3
        mov dl,0C3h
        mov dh,0B4h
        mov al,0C4h
        call hline
        ; title from the program's own file name
        call myname
        mov bx,TOP+1
        mov ah,TITLE
        call center
        mov si,subtitle
        mov bx,TOP+2
        mov ah,BACK
        call center
        ; explanation, one line per string, empty string ends
        mov si,text
        mov bx,TOP+5
.text:  cmp byte [si],0
        je .wait
        mov di,bx
        imul di,160
        add di,(LEFT+3)*2
        mov ah,FRAME
        call puts
        inc bx
        jmp .text
.wait:  xor ah,ah               ; wait for a key
        int 16h
        mov ax,0700h | ' '      ; clear to grey on black, cursor back
        xor di,di
        mov cx,25*80
        rep stosw
        mov ah,1
        mov cx,0607h
        int 10h
        mov ah,2
        xor bh,bh
        xor dx,dx
        int 10h
        mov ax,4C00h
        int 21h

; draw row BX of the window: DL left corner, AL fill, DH right corner
hline:  push cx
        mov di,bx
        imul di,160
        add di,LEFT*2
        mov ah,FRAME
        push ax
        mov al,dl
        stosw
        pop ax
        mov cx,WIDTH-2
        rep stosw
        mov al,dh
        stosw
        pop cx
        ret

; write the string at SI (0-terminated) to ES:DI with attribute AH
puts:   lodsb
        or al,al
        jz .done
        stosw
        jmp puts
.done:  ret

; centre the string at SI in row BX of the window, attribute AH
center: push si
        xor cx,cx
.len:   cmp byte [si],0
        je .go
        inc si
        inc cx
        jmp .len
.go:    pop si
        mov di,WIDTH
        sub di,cx
        shr di,1
        add di,LEFT
        mov dx,bx
        imul dx,160
        shl di,1
        add di,dx
        jmp puts

; SI := display name for this program's file name
myname: push es
        mov es,[2Ch]            ; environment: strings, 0, count, path
        xor di,di
.env:   cmp word [es:di],0
        je .path
        inc di
        jmp .env
.path:  add di,4                ; skip 0,0 and the string count
        mov si,di
.last:  mov al,[es:di]          ; remember the start after the last '\'
        or al,al
        jz .base
        inc di
        cmp al,'\'
        jne .last
        mov si,di
        jmp .last
.base:  mov di,base             ; copy the base name, up to '.'
.copy:  mov al,[es:si]
        cmp al,'.'
        je .end
        or al,al
        jz .end
        mov [di],al
        inc si
        inc di
        cmp di,base+8
        jb .copy
.end:   mov byte [di],0
        pop es
        mov bx,names            ; look it up: "FILE",0,"Display name",0
.find:  cmp byte [bx],0
        je .unknown
        mov si,base
        mov di,bx
.cmp:   mov al,[si]
        cmp al,[di]
        jne .next
        or al,al
        jz .found
        inc si
        inc di
        jmp .cmp
.next:  cmp byte [bx],0         ; skip key and display name
        je .skip1
        inc bx
        jmp .next
.skip1: inc bx
.skip2: cmp byte [bx],0
        je .skip3
        inc bx
        jmp .skip2
.skip3: inc bx
        jmp .find
.found: lea si,[di+1]
        ret
.unknown:
        mov si,base
        ret

names:  db 'NC',0,'Norton Commander',0
        db 'WP',0,'WordPerfect 5.1',0
        db 'TURBO',0,'Turbo Pascal 6.0',0
        db '123',0,'Lotus 1-2-3',0
        db 'DBASE',0,'dBASE IV',0
        db 'WIN',0,'Windows 3.1',0
        db 'VENTURA',0,'Ventura Publisher',0
        db 'HG',0,'Harvard Graphics',0
        db 'DP',0,'Harvard Graphics Draw Partner',0
        db 0

subtitle:
        db '- a museum stand-in, not the real program -',0

text:
%ifdef V1
        db 'Power-Choice 1.0e started this program from its menu.',0
        db 0FFh,0
        db 'The clock in the top right corner is not part of it:',0
        db 'PCH_LL, the resident driver of Power-Choice, draws it',0
        db 'on top of whatever runs, if the menu item says Clock = Y.',0
        db 0FFh,0
        db "The 1990 screen saver needs a Hercules, CGA or EGA card;",0
        db 'this emulated PC has VGA, so it stays off, as in 1990.',0
        db 0FFh,0
        db 'Press any key to return to Power-Choice.',0
%else
        db 'Power-Choice 3.1 started this program from its menu.',0
        db 0FFh,0
        db 'The clock in the top right corner is not part of it:',0
        db 'PCHEGA, the resident driver of Power-Choice, draws it',0
        db 'on top of any text-mode program.',0
        db 0FFh,0
        db "Leave the keyboard alone for a minute and PCHEGA's",0
        db 'screen saver switches the screen off. Any key wakes it.',0
        db 0FFh,0
        db 'Press any key to return to Power-Choice.',0
%endif
        db 0

base:   times 9 db 0
