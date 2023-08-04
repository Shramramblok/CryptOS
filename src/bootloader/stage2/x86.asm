bits 16

section _TEXT class=CODE
;        o
;        f
;        f s
;        s i
;        e z
;        t e
;        V V
; ----SS---- 
; BP     0 2 <-- SP
; IP     2 2
; char   4 2
; page   6 2
; ----------
%define char [bp + 4]
%define page [bp + 6]
global _x86_WriteChar
_x86_WriteChar:
    push bp
    mov bp, sp ; save stack frame
    push bx ; save bx

    mov ah, 0x0e ; BIOS teletype function
    mov al, char ; character to print
    mov bh, page ; page number
    int 0x10 ; call BIOS

    pop bx ; restore bx
    mov sp, bp
    pop bp ; restore stack frame
    ret
    ret