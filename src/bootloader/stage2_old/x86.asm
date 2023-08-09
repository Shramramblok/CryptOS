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
; ------------------
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

;          o
;          f
;          f s
;          s i
;          e z
;          t e
;          V V
; -----SS-----
; BP       0 2 <-- SP
; IP       2 2
; drive    4 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; ------------
%define drive [bp + 4]
global _x86_ResetDisk
_x86_ResetDisk:
    push bp
    mov bp, sp ; save stack frame

    mov ah, 0x0 ; BIOS reset drive function
    mov dl, drive ; drive number
    stc ; set carry flag
    int 0x13 ; call BIOS

    mov ax, 1
    sbb ax, 0 ; ax = 0 if carry flag is set, 1 otherwise

    mov sp, bp
    pop bp ; restore stack frame
    ret


;                  o
;                  f
;                  f s
;                  s i
;                  e z
;                  t e
;                  V V
; ---------SS---------
; BP               0 2 <-- SP
; IP               2 2
; drive            4 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; cylinder         6 2
; head             8 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; sector          10 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; count           12 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; far_ptr_buffer  14 4
; --------------------
%define drive [bp + 4]
%define cylinderLower [bp + 6]
%define cylinderUpper [bp + 7]
%define head [bp + 8]
%define sector [bp + 10]
%define count [bp + 12]
%define offset_ptr_buffer [bp + 14]
%define segment_ptr_buffer [bp + 16]
global _x86_ReadDisk
_x86_ReadDisk:
    push bp
    mov bp, sp ; save stack frame

    push bx ; save bx
    push es ; save es

    mov dl, drive ; drive number

    mov ch, cylinderLower ; cylinder number
    mov cl, cylinderUpper ; cylinder number
    shl cl, 6 ; shift cylinder number to the left by 6 bits

    mov dh, head ; head number

    mov al, sector ; sector number
    and al,  00111111b ; clear the 2 most significant bits
    or cl, al ; add sector number

    mov al, count ; number of sectors to read

    mov bx, segment_ptr_buffer
    mov es, bx ; set es to the segment of the buffer
    mov bx, offset_ptr_buffer

    mov ah, 0x2 ; BIOS reset drive function
    stc ; set carry flag
    int 0x13 ; call BIOS

    mov ax, 1
    sbb ax, 0 ; ax = 0 if carry flag is set, 1 otherwise

    pop es ; restore es
    pop bx ; restore bx

    mov sp, bp
    pop bp ; restore stack frame
    ret

;                  o
;                  f
;                  f s
;                  s i
;                  e z
;                  t e
;                  V V
; ---------SS---------
; BP               0 2 <-- SP
; IP               2 2
; drive            4 2 <-- (actually a byte, but you can only push/pop a minimum of 2 bytes)
; ptr_cylinders    6 2
; ptr_heads        8 2
; ptr_sectors     10 2
; ptr_driveType   12 2
; --------------------
%define drive [bp + 4]
%define ptr_cylinders [bp + 6]
%define ptr_heads [bp + 8]
%define ptr_sectors [bp + 10]
%define ptr_driveType [bp + 12]
global _x86_GetDiskParameters
_x86_GetDiskParameters:
    push bp
    mov bp, sp ; save stack frame

    push bx ; save bx
    push di ; save di
    push si ; save si
    push es ; save es

    mov dl, drive ; drive number

    mov ah, 0x8 ; BIOS reset drive function
    xor di, di ; di = 0
    mov es, di ; es = 0
    stc ; set carry flag
    int 0x13 ; call BIOS

    mov ax, 1
    sbb ax, 0 ; ax = 0 if carry flag is set, 1 otherwise

    mov si, ptr_driveType
    mov [si], bl ; store drive type

    ;mov bl, ch ; store low 8 bits of maximum cylinder number
    mov si, ptr_sectors
    mov [si], cl ; store maximum sector number, cl bits 0-5
    and [si], byte 00111111b ; clear the 2 most significant bits

    shr cl, 6 ; get high 2 bits of maximum cylinder number
    mov si, ptr_cylinders
    mov [si], cx ; store maximum cylinder number

    mov si, ptr_heads
    mov [si], dh ; store maximum head number


    pop es ; restore es
    pop si ; restore si
    pop di ; restore di
    pop bx ; restore bx

    mov sp, bp
    pop bp ; restore stack frame
    ret

; Unsigned 4 byte divide
; Dividend = DX:AX     
; Divisor = CX:BX    
; Quotient = DX:AX      
; Remainder = CX:BX 
global __U4D
__U4D:
    shl edx, 16
    mov dx, ax
    mov eax, edx
    xor edx, edx ; edx:eax = Dividend

    shl ecx, 16
    mov cx, bx ; ecx = Divisor

    div ecx

    mov ebx, edx
    mov ecx, ebx
    shr ecx, 16 ; cx:bx = Remainder

    mov edx, eax
    shr edx, 16 ; dx:ax = Quotient

    ret
