bits 16

section .entry

extern __bss_start ; bss section symbol
extern __end ; end of sections symbol

extern cppstart

; constants for enabling A20 gate:
KBDCntrlDataPort equ 0x60
KBDCntrlCommandPort equ 0x64
KBDCntrlDisableKBD equ 0xAD
KBDCntrlEnableKBD equ 0xAE
KBDCntrlReadCntrlOutPort equ 0xD0
KBDCntrlWriteCntrlOutPort equ 0xD1
global entry
entry:
    cli

    mov [g_BootDrive], dl ; save boot drive number (will be lost in the transition)
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp
    
; Real mode -> Protected mode, steps are mentioned by the order of the intel manual chapter 9.9.1

    ; disable all interrupts (step 1, are already disabled)
    
    ; enable A20 gateway (NOT IN MANUAL), allow us to access more than the 1MB provided in real-mode
    call enable_A20
    
    ; setting the GDT register to our GDT (step 2)
    call load_GDT

    ; set cr0 last bit to 1 to go into protected mode (step 3)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; far jump into the 32-bit code segment to perform the switch (step 4)
    jmp dword CODE32_SEG:.protected_begin
.protected_begin:
    [bits 32]
    
    ; Paging is not enabled (step 6) ,LDT is not used (step 7), Tasking is not used (step 8)
    
    ; setup segment register by the GDT (step 9), note: ES, FS, GS will stay 0 from entry label
    mov ax, DATA32_SEG ; 32-bit DATA_SEG
    mov ds, ax
    mov ss, ax
    
    ; fill bss section with zeroes (uninitialized data, remember rachel):
    mov edi, __bss_start
    mov ecx, __end 
    sub ecx, edi ; ecx = length of bss section
    mov al, 0
    cld ; edi should increment and not decrement
    rep stosb ; [edi] = al, edi++, ecx-- (REPeats until ecx = 0)
    
    xor edx, edx
    mov dl, [g_BootDrive] ; restore boot drive number
    push edx
    call cppstart
    cli ; disable interrupts
    hlt ; halt


enable_A20: ; enable the A20 gateway to stop restricting the data to the 1MB of memory
    [bits 16]

    ; part 1 - disable the keyboard
    call A20_input
    mov al, KBDCntrlDisableKBD
    out KBDCntrlCommandPort, al

    ; part 2 - read from control output port (read output buffer)
    call A20_input
    mov al, KBDCntrlReadCntrlOutPort
    out KBDCntrlCommandPort, al

    call A20_output
    in al, KBDCntrlDataPort
    push eax ; eax will hold the value for the output port
    
    ; part 3 - write to control output port (set bit 1 to enable A20 gateway)
    call A20_input
    mov al, KBDCntrlWriteCntrlOutPort
    out KBDCntrlCommandPort, al

    call A20_input
    pop eax
    or al, 2
    out KBDCntrlDataPort, al

    ; (part 4) - re-enable the keyboard
    call A20_input
    mov al, KBDCntrlEnableKBD
    out KBDCntrlCommandPort, al
    
    call A20_input
    ret

    A20_input: ; wait until status bit 2 (input buffer) is 0 - input is done
    [bits 16]
    in al, KBDCntrlCommandPort
    test al, 2
    jnz A20_input
    ret


    A20_output: ; wait until status bit 1 (output buffer) is 0 - input can be read
    [bits 16]
    test al, 1
    jnz A20_output
    ret


load_GDT: ; load the GDT into the GDT register
    [bits 16]
    lgdt [GDT_descriptor]
    ret


; si = address of message to print
real_print: ; print a message to the screen
    .realpr_loop:
        lodsb ; mov al <- [byte ptr si], esi++
        or al, al
        jz .realpr_done  
        mov ah, 0xe
        int 10h
        jmp .realpr_loop

    .realpr_done:
    ret


; GDT:
GDT_begin: ; minimal descriptors, each is 8 bytes

    null_descriptor:  ; required empty first descriptor
        dd 0 ; 00000000 X 4 times
        dd 0 ; 00000000 X 4 times

    code_32: ; 32-bit code segment (used when passing from 16bit(real) to 32bit(protected))
        dw 0xffff
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0

    data_32: ; 32-bit data segment (used when passing from 16bit(real) to 32bit(protected))
        dw 0xffff
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

    code_16: ; 16-bit code segment (used when passing from 32bit to 16bit, still protected)
        dw 0xffff
        dw 0
        db 0
        db 10011010b
        db 00001111b
        db 0

    data_16: ; 16-bit data segment (used when passing from 32bit to 16bit, still protected)
        dw 0xffff
        dw 0
        db 0
        db 10010010b
        db 00001111b
        db 0
GDT_end:  ; the GDT ends here, not really important
    GDT_descriptor:
        dw GDT_descriptor - GDT_begin - 1 ; size of GDT (limit)
        dd GDT_begin ; start of GDT (address)
    
CODE16_SEG equ code_16 - GDT_begin ; pointer for 16-bit CODE_SEG in GDT (protected)
DATA16_SEG equ data_16 - GDT_begin ; pointer for 16-bit DATA_SEG in GDT (protected)   
CODE32_SEG equ code_32 - GDT_begin ; pointer for 32-bit CODE_SEG in GDT (protected)
DATA32_SEG equ data_32 - GDT_begin ; pointer for 32-bit DATA_SEG in GDT (protected)

prot_msg: db "Successful switch to protected mode :)!", 0
real_msg: db "Successful switch back to real mode :)!", 0
g_BootDrive: db 0