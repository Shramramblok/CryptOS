bits 16

section _TEXT class=CODE


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