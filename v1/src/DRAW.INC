b_cnt     equ 2
c_mask    equ 8
neg_ch    equ 9
shift_ch  equ 10
pix_mask  equ 11
shift_hr  equ 12
max_block equ 1
reset_b   equ 2
byte_nr   equ 8

x1        equ 4
y1        equ 6
x2        equ 8
y2        equ 10
color_prm equ 12

text     segment byte public 'CODE'
         assume cs:text,ds:data

draw     proc near
         cli
         push bp
         mov bp,sp
         push di
         push si
         xor dl,dl
         mov si,[bp]+x2
         cmp si,max_x
         ja jmp_exit
         mov bx,[bp]+y2
         cmp bx,max_y
         ja jmp_exit
         sub si,[bp]+x1
         jae sub_y
         neg si
         or dl,1000b
sub_y:   sub bx,[bp]+y1
         jae compare
         neg bx
         or dl,100b
compare: cmp si,bx
         jae save_dif
         xchg si,bx
         or dl,10000b
save_dif:cmp si,0
         je jmp_exit
         mov sdif,bx
         mov ax,si
         shr ax,1
         push si
         push ax
         call get_mode
         cmp si,-1
         jne adr
clr_stck:add sp,4
jmp_exit:jmp exit_d
adr:     call get_y
         cmp si,-1
         je clr_stck
         xor bl,bl
         mov binc,1
         mov cx,[si]+b_cnt
byte_cnt:shr ax,1
         jnc next_bt
         add di,blockadd
         add bl,binc
next_bt: sal blockadd,1
         sal binc,1
         loop byte_cnt
         call add_offs
         cmp si,-1
         je clr_stck
draw_ln: pop ax
         mov ch,dh
         mov dh,[bp]+color_prm
         and dh,[si]+c_mask
         neg ch
         add ch,[si]+neg_ch
         mov cl,[si]+shift_ch
         shl ch,cl
         mov cl,ch
         shl dh,cl
         mov bh,[si]+pix_mask
         rol bh,cl
         pop cx
         mov bp,cx
         add si,shift_hr
set_pix: and es:[di],bh
         or es:[di],dh
         test dl,10000b
         jz hr
         call mov_vert
         call chg_hr
loop_sp: loop set_pix
         jmp short exit_d
hr:      call mov_hr
         call chg_vert
         loop set_pix
exit_d:  pop si
         pop di
         pop bp
         sti
         ret
draw     endp

chg_vert proc near
         call pos_chg
         test dl,100000b
         jz exit_cv
         call mov_vert
exit_cv: ret
chg_vert endp

mov_vert proc near
         test dl,100b
         jnz up
         cmp bl,[si]+max_block
         je ln_down
         add di,2000h
         inc bl
         ret
ln_down: mov bl,0
         sub di,[si]+reset_b
         add di,[si]-byte_nr
         ret
up:      cmp bl,0
         je ln_up
         sub di,2000h
         dec bl
         ret
ln_up:   mov bl,[si]+max_block
         add di,[si]+reset_b
         sub di,[si]-byte_nr
         ret
mov_vert endp

chg_hr   proc near
         call pos_chg
         test dl,100000b
         jz exit_ch
         call mov_hr
exit_ch: ret
chg_hr   endp

mov_hr   proc near
         push cx
         mov cl,[si]
         test dl,1000b
         jz l_to_r
         rol dh,cl
         rol bh,cl
         jc exit_mh
         dec di
         pop cx
         ret
l_to_r:  ror dh,cl
         ror bh,cl
         jc exit_mh
         inc di
exit_mh: pop cx
         ret
mov_hr   endp

pos_chg  proc near
         and dl,11111b
         add ax,sdif
         cmp bp,ax
         jae exit_pc
         or dl,100000b
         sub ax,bp
exit_pc: ret
pos_chg  endp

text     ends

data     segment word public 'DATA'

sdif     dw ?
binc     db ?

data     ends
