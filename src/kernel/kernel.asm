org 0x7c00
bits 16

jmp main

%define ENDL 0x0D, 0x0A

%macro _print 1
    mov si, %1 ; si = str
    call print ; print(str)
%endmacro

%define print(s) _print s

print:
    push si ; save si
    push ax ; save ax
    lodsb ; al = [si], si++
    or al, al ; al == 0?
    jz .done_print ; yes, done

    xor bh, bh ; page 0
    mov ah, 0x0e ; tty mode
    int 0x10 ; print al

    jmp print ; no, print next char

.done_print:
    pop ax ; restore ax
    pop si ; restore si
    ret ; return

main:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7c00

    print(msg)

    hlt

.halt:
    jmp .halt

msg: db "Hello, World!", 0

times 510-($-$$) db 0
dw 0xaa55