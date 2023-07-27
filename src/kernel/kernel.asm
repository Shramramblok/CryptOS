org 0x0
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
    print(msg)

.halt:
    cli
    hlt



msg: db "Hello world from CryptOS Kernel!", 0