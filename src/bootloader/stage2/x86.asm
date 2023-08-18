bits 16

section _TEXT class=CODE
%include "protmode.asm" 


;                o
;                f
;                f s
;                s i
;                e z
;                t e
;                V V
; --------SS--------
; EBP            0 4 <-- ESP
; EIP            4 4
; character      8 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; ------------------
global x86_RealModePutC
x86_RealModePutC:
    [bits 32]
    push ebp
    mov ebp, esp

    x86_EnterReal
    mov al, [bp + 8]
    mov ah, 0xe
    int 10h
    
    push eax
    x86_EnterProtected
    pop eax
    
    mov esp, ebp
    pop ebp
    ret


; DISK FUNCTIONS:

;                  o
;                  f
;                  f s
;                  s i
;                  e z
;                  t e
;                  V V
; ---------SS---------
; EBP              0 4 <-- ESP
; EIP              4 4
; drive            8 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; ptr_cylinders   12 4
; ptr_heads       16 4
; ptr_sectors     20 4
; ptr_driveType   24 4
; --------------------
%define drive [bp + 8]
%define ptr_cylinders [bp + 12]
%define ptr_heads [bp + 16]
%define ptr_sectors [bp + 20]
%define ptr_driveType [bp + 24]
global x86_GetDiskParamsProt
x86_GetDiskParamsProt:
    [bits 32]
    push ebp
    mov ebp, esp ; save stack frame
    x86_EnterReal ; enter real mode to use BIOS interrupts

    push bx ; save ebx
    push di ; save edi
    push esi ; save esi
    push es ; save es

    mov dl, drive ; drive number

    mov ah, 0x8 ; BIOS reset drive function
    xor di, di ; di = 0
    mov es, di ; es = 0
    stc ; set carry flag
    int 0x13 ; call BIOS

    ; DriveType
    LinToSegOfs ptr_driveType, es, esi, si
    mov [es:si], bl ; store drive type

    ; PtrSectors
    ;mov bl, ch ; store low 8 bits of maximum cylinder number
    LinToSegOfs ptr_sectors, es, esi, si
    mov [es:si], cl ; store maximum sector number, cl bits 0-5
    and [es:si], byte 00111111b ; clear the 2 most significant bits

    ; PtrCylinders
    shr cl, 6 ; get high 2 bits of maximum cylinder number
    LinToSegOfs ptr_cylinders, es, esi, si
    mov [es:si], cx ; store maximum cylinder number

    ; PtrHeads
    LinToSegOfs ptr_heads, es, esi, si
    mov [es:si], dh ; store maximum head number

    pop es ; restore es
    pop esi ; restore esi
    pop di ; restore di
    pop bx ; restore bx

    ; return
    mov eax, 1
    sbb eax, 0 ; eax = 0 if carry flag is set, 1 otherwise
    push eax ; changed when entering protmode
    x86_EnterProtected ; go back to protected mode
    pop eax

    mov esp, ebp
    pop ebp ; restore stack frame
    ret


;          o
;          f
;          f s
;          s i
;          e z
;          t e
;          V V
; -----SS-----
; EBP       0 4 <-- ESP
; EIP       4 4
; drive     8 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; ------------
%define drive [bp + 8]
global x86_ResetDiskProt
x86_ResetDiskProt:
    [bits 32]
    push ebp
    mov ebp, esp ; save stack frame

    x86_EnterReal
    mov ah, 0x0 ; BIOS reset drive function
    mov dl, drive ; drive number
    stc ; set carry flag
    int 0x13 ; call BIOS

    mov eax, 1
    sbb eax, 0 ; eax = 0 if carry flag is set, 1 otherwise

    push eax
    x86_EnterProtected
    pop eax

    mov esp, ebp
    pop ebp ; restore stack frame
    ret


;                  o
;                  f
;                  f s
;                  s i
;                  e z
;                  t e
;                  V V
; ---------SS---------
; EBP              0 4 <-- ESP
; EIP              4 4
; drive            8 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; cylinder        12 4 <-- (value is actually two bytes but alligned to 4_LITTLE because of 32bit)
; head            16 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; sector          20 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; count           24 4 <-- (value is actually one byte but alligned to 4_LITTLE because of 32bit)
; ptr_buffer      28 4
; --------------------
%define drive [bp + 8]
%define cylinderLower [bp + 12]
%define cylinderUpper [bp + 13]
%define head [bp + 16]
%define sector [bp + 20]
%define count [bp + 24]
%define ptr_buffer [bp + 28]
global x86_ReadDiskProt
x86_ReadDiskProt:
    [bits 32]
    push ebp
    mov ebp, esp ; save stack frame

    push ebx ; save bx
    push es ; save es
    
    x86_EnterReal
    mov dl, drive ; drive number

    mov ch, cylinderLower ; cylinder number
    mov cl, cylinderUpper ; cylinder number
    shl cl, 6 ; shift cylinder number to the left by 6 bits

    mov dh, head ; head number

    mov al, sector ; sector number
    and al,  00111111b ; clear the 2 most significant bits
    or cl, al ; add sector number

    mov al, count ; number of sectors to read

    LinToSegOfs ptr_buffer, es, ebx, bx ; es:bx = ptr_buffer
    ;mov bx, segment_ptr_buffer
    ;mov es, bx ; set es to the segment of the buffer
    ;mov bx, offset_ptr_buffer

    mov ah, 0x2 ; BIOS reset drive function
    stc ; set carry flag
    int 0x13 ; call BIOS

    mov eax, 1
    sbb eax, 0 ; eax = 0 if carry flag is set, 1 otherwise

    push eax
    x86_EnterProtected
    pop eax

    pop es ; restore es
    pop ebx ; restore ebx

    mov esp, ebp
    pop ebp ; restore stack frame
    ret


;                o
;                f
;                f s
;                s i
;                e z
;                t e
;                V V
; --------SS--------
; EBP            0 4 <-- ESP
; EIP            4 4
; dividend       8 8
; divisor       16 4
; ptr_quotient  20 4
; ptr_remainder 24 4 
; ------------------
%define dividendLower [bp + 8]
%define dividendUpper [bp + 12]
%define divisor [bp + 16]
%define ptr_quotient [bp + 20]
%define ptr_remainder [bp + 24]
global x86_Divide_64_32_Prot
x86_Divide_64_32_Prot:
    [bits 32]
    push ebp
    mov ebp, esp ; save stack frame

    x86_EnterReal
    push ebx ; save bx
    push es ; save es

    mov eax, dividendUpper
    mov ecx, divisor
    xor edx, edx
    div ecx ; eax = edx:eax / ecx, edx = edx:eax % ecx

    LinToSegOfs ptr_quotient, es, ebx, bx
    ; mov bx, ptr_quotient
    mov [es:bx + 4], eax ; might be a problem - +4 is unkown (might not fit protmode)


    mov eax, dividendLower
    ; edx have the remainder from the previous division
    div ecx ; eax = edx:eax / ecx, edx = edx:eax % ecx

    mov [es:bx], eax
    ; mov bx, ptr_remainder
    LinToSegOfs ptr_remainder, es, ebx, bx
    mov [es:bx], edx

    pop es ; restore es
    pop ebx ; restore bx

    push eax
    x86_EnterProtected
    pop eax

    mov esp, ebp
    pop ebp ; restore stack frame
    ret


;                o
;                f
;                f s
;                s i
;                e z
;                t e
;                V V
; --------SS--------
; EBP            0 4 <-- ESP
; EIP            4 4
; port number    8 4 <-- value is actually two bytes but alligned to 4_LITTLE because of 32bit
; value         12 4 <-- value is actually one byte but alligned to 4_LITTLE because of 32bit
; ------------------
global x86_outb
x86_outb:
    [bits 32]
    mov dx, [bp + 8]
    mov al, [bp + 12]
    out dx, al
    ret


;                o
;                f
;                f s
;                s i
;                e z
;                t e
;                V V
; --------SS--------
; EBP            0 4 <-- ESP
; EIP            4 4
; port number    8 4 <-- value is actually two bytes but alligned to 4_LITTLE because of 32bit
; ------------------
global x86_inpb
x86_inpb:
    [bits 32]
    mov dx, [bp + 8]
    xor eax, eax
    in al, dx
    ret