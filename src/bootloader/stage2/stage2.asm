org 0x0000
bits 16

%define ENDL 0x0D, 0x0A

%macro print$ 1
    xor cx, cx ; cx = 0
    mov si, %1 ; si = str
    call print ; print(str)
%endmacro




main:
    print$ msg ; print(msg)
    
.halt:
    cli
    hlt

print:
    push si ; save si
    push ax ; save ax
    push cx ; save cx
    .print_loop:
    dec cx ; cx--
    lodsb ; al = [si], si++
    or al, al ; al == 0?
    jz .done_print ; yes, done

    xor bh, bh ; page 0
    mov ah, 0x0e ; tty mode
    int 0x10 ; print al

    or cx, cx ; cx == 0?
    jnz .print_loop ; no, print next char
    .done_print:
        pop cx ; restore cx
        pop ax ; restore ax
        pop si ; restore si
    ret ; return



msg: db "Running Stage 2 of CryptOS!", 0