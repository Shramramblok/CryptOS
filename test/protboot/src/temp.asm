org 0x7C00
[bits 16]
GDT_begin: ; the GDT starts here, only required are null + code + data
    null_descriptor:  ; required empty first descriptor
        dd 0 ; 00000000 X 4 times
        dd 0 ; 00000000 X 4 times
    code_descriptor: ; descriptor for the code segment in the GDT
        dw 0xffff
        dw 0
        db 0
        db 10011010
        db 11001111
        db 0
    data_descriptor: ; descriptor for the data segment in the GDT
        dw 0xffff
        dw 0
        db 0
        db 10010010
        db 11001111
        db 0
GDT_end:  ; the GDT ends here
    GDT_descriptor:
        dw GDT_end - GDT_begin - 1 ; size of GDT
        dd GDT_begin ; start of GDT
CODE_SEG equ code_descriptor - GDT_begin ; constant for code descriptor in GDT
DATA_SEG equ data_descriptor - GDT_begin ; constant for data descriptor in GDT

cli ; disable all interrupts

lgdt [GDT_descriptor] ; setting the GDT register to our GDT

in al, 0x92	; enable A20 gateway, allow us to access more than the 1MB provided in real-mode
or al, 2
out 0x92, al

xor ax, ax ; clear all segments before transfering (except ss)
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax

mov eax, cr0 ; set cr0 last bit to 1 to go into protected mode
or eax, 1
mov cr0, eax

jmp CODESEG:protected_begin ; far jump into the code segment

[bits 32]
protected_begin: ; this section is used to run the kernel in protected mode
    mov al, 'A'
    mov ah, 0x0f
    mov [0xb8000], ax ; DS:0xb8000
    ; this check is performed to see if transition worked, as there are no BIOS ints in ring0
    ; HERE: IMPLEMENT STAGE 2 MAIN
