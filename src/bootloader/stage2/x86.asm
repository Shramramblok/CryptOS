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

;                o
;                f
;                f s
;                s i
;                e z
;                t e
;                V V
; --------SS--------
; BP             0 2 <-- SP
; IP             2 2
; dividend       4 8
; divisor       12 4
; ptr_quotient  16 2
; ptr_remainder 18 2
; ----------------
%define dividendLower [bp + 4]
%define dividendUpper [bp + 8]
%define divisor [bp + 12]
%define ptr_quotient [bp + 16]
%define ptr_remainder [bp + 18]
global _x86_Divide_64_32
_x86_Divide_64_32:
    push bp
    mov bp, sp ; save stack frame

    push bx ; save bx

    mov eax, dividendUpper
    mov ecx, divisor
    xor edx, edx
    div ecx ; eax = edx:eax / ecx, edx = edx:eax % ecx

    mov bx, ptr_quotient
    mov [bx + 4], eax

    mov eax, dividendLower
    ; edx have the remainder from the previous division
    div ecx ; eax = edx:eax / ecx, edx = edx:eax % ecx

    mov [bx], eax
    mov bx, ptr_remainder
    mov [bx], edx

    pop bx ; restore bx

    mov sp, bp
    pop bp ; restore stack frame
    ret