bits 16

section _TEXT class=CODE
; ---SS---
; BP     0
; IP     2
; CHAR   4
; PAGE   6
; --------
CHAR equ [bp + 4]
PAGE equ [bp + 6]
global _x86_WriteChar
_x86_WriteChar:
    enter ; save stack frame
    push bx ; save bx

    mov ah, 0x0e ; BIOS teletype function
    mov al, CHAR ; character to print
    mov bh, PAGE ; page number
    int 0x10 ; call BIOS

    pop bx ; restore bx
    leave ; restore stack frame
    ret