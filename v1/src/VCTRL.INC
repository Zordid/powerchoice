cga        equ 1
color_reg  equ 3d9h
index      equ 03b4h
ctrl       equ 03b8h
config     equ 03bfh
param      equ 4
if cga
param2     equ 6
endif
hires      equ 6
lowres     equ 4
text_80    equ 3
text_40    equ 1
text_mono  equ 7
graph_mono equ 17

text     segment byte public 'CODE'
         assume cs:text,ds:data,ss:data

videomode proc near
         push bp
         mov bp,sp
         mov dx,[bp]+param
         xor dh,dh
         mov al,dl
         mov ah,00h
         cmp al,hires
         jne lr
         mov max_x,639
         mov max_y,199
if cga
         mov color,15
endif
         jmp short call_int
lr:      cmp al,lowres
         jne t_80
         mov max_x,319
         mov max_y,199
if cga
         mov color,0
         mov plt,20h
         mov plt_int,0
endif
         jmp short call_int
t_80:    cmp al,text_80
         jne t_40
         mov max_x,79
         mov max_y,24
if cga
         mov color,0
endif
         jmp short call_int
t_40:    cmp al,text_40
         jne t_mono
         mov max_x,39
         mov max_y,24
if cga
         mov color,0
endif
         jmp short call_int
t_mono:  cmp al,text_mono
         jne g_mono
         mov max_x,79
         mov max_y,24
         jmp short call_int
g_mono:  cmp al,graph_mono
         jne exit_v
         mov vmode,dx
         mov max_x,719
         mov max_y,347
         call setgraph
         jmp short exit_v
call_int:mov vmode,dx
         int 10h
exit_v:  pop bp
         ret

setgraph proc near
mono_seg equ 0b000h
graph    equ 10b
scr_on   equ 1010b
         push si
         push di
         lea si,vtable
         mov al,1
         mov dx,config
         out dx,al
         mov al,graph
         mov dx,ctrl
         out dx,al
         mov dx,index
         mov cx,12
         xor ah,ah
         cld
next_reg:mov al,ah
         out dx,al
         inc dx
         lodsb
         out dx,al
         inc ah
         dec dx
         loop next_reg
         mov ax,mono_seg
         mov es,ax
         mov cx,4000h
         xor ah,ah
         xor di,di
         rep stosw
         mov al,scr_on
         mov dx,ctrl
         out dx,al
         pop di
         pop si
         ret
setgraph endp
videomode endp

palette proc near
        push bp
        mov bp,sp
if cga
        mov ax,[bp]+param
        xor ah,ah
        cmp ax,1
        ja exit_p
        mov dx,[bp]+param2
        xor dh,dh
        cmp dx,1
        ja exit_p
        mov cl,5
        shl ax,cl
        mov plt,ax
        dec cl
        shl dx,cl
        mov plt_int,dx
        or ax,dx
        or ax,color
        mov dx,color_reg
        out dx,al
else
        mov ah,0bh
        mov bh,1
        mov bl,[bp]+param
        cmp bl,1
        ja exit_p
        int 10h
endif
exit_p: pop bp
        ret
palette endp

hirescolor  proc near
bordercolor proc near
lowresbg    proc near
        push bp
        mov bp,sp
if cga
        mov ax,[bp]+param
        xor ah,ah
        cmp al,15
        ja exit_b
        mov color,ax
        or ax,plt
        or ax,plt_int
        mov dx,color_reg
        out dx,al
else
        mov ah,0bh
        mov bh,0
        mov bl,[bp]+param
        cmp bl,15
        ja exit_b
        int 10h
endif
exit_b: pop bp
        ret
lowresbg    endp
bordercolor endp
hirescolor  endp

text     ends

data     segment word public 'DATA'
vmode    dw -1
max_x    dw -1
max_y    dw -1

if cga
color    dw 0
plt      dw 20h
plt_int  dw 0
endif

vtable   db 35h,2dh,2eh,07h
         db 5bh,02h,57h,57h
         db 02h,03h,00h,00h

data     ends