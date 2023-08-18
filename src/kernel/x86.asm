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

    ; DriveTyp
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