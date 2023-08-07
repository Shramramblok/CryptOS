org 0x7c00
bits 16

KBDCntrlDataPort equ 0x60
KBDCntrlCommandPort equ 0x64
KBDCntrlDisableKBD equ 0xAD
KBDCntrlEnableKBD equ 0xAE
KBDCntrlReadCntrlOutPort equ 0xD0
KBDCntrlWriteCntrlOutPort equ 0xD1

entry:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov sp, 0x7c00 ; stack grows downwards

; Real mode -> Protected mode, steps are mentioned by the order of the intel manual chapter 9.9.1

    ; disable all interrupts (step 1)
    cli 
    
    ; enable A20 gateway (NOT IN MANUAL), allow us to access more than the 1MB provided in real-mode
    call enable_A20
    
    ; setting the GDT register to our GDT (step 2)
    call load_GDT

    ; set cr0 last bit to 1 to go into protected mode (step 3)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; far jump into the 32-bit code segment to perform the switch (step 4)
    jmp dword PRCODE_SEG:.protected_begin

.protected_begin:
    [bits 32]
    
    ; Paging is not enabled (step 6) ,LDT is not used (step 7), Tasking is not used (step 8)
    
    ; setup segment register by the GDT (step 9), note: ES, FS, GS will stay 0 from entry label
    mov ax, PRDATA_SEG ; 32-bit DATA_SEG is the third in the GDT - offset 16
    mov ds, ax
    mov ss, ax
    
    ; steps 10, 11 are about interrupt descriptor tables (future video)

    ; test protected mode by printing text to the screen (0xb8000 is mapped straight to display, OPHINT):
    mov esi, prot_msg
    mov edi, 0xb8000
    push ax
    push bx
    cld
    mov bl, 1

    .protpr_loop:
        lodsb ; mov al <- [byte ptr si], esi++
        or al, al
        jz .protpr_done  
        mov [edi], al
        inc edi
        mov [edi], byte bl ; color
        inc edi
        inc bl
        jmp .protpr_loop

    .protpr_done:
    pop bx
    pop ax

; Protected mode -> Real mode, steps are mentioned by the order of the intel manual chapter 9.9.2
    ; step 1 (disable interrupts) is already done and step 2 (disable Paging) is not relevant

    ; far jump into the 16-bit code segment (step 3)
    jmp dword RLCODE_SEG:.protected_16bit
    
.protected_16bit: ; technically, here its still (16-bit) protected mode
    [bits 16]

    ; step 4 is not relevant (no need to use data/code in protected -> real)
    
    ; step 5 is not relevant yet (until a future video there is no interrupt descriptor table)
    
    ; set cr0 last bit to 0 to go into real mode (step 6)
    mov eax, cr0
    and eax, ~1
    mov cr0, eax

    ; far jump to start real mode 16-bit code execution (step 7)
    jmp dword 0x0:.protected_end

.protected_end:

    ; setup segments (step 8)
    xor ax, ax
    mov ds, ax
    mov ss, ax

    ; enable interrupts (step 9)
    sti

    ; test real mode by printing text to the screen using BIOS interrupts
    mov si, real_msg
    call real_print


.halt:
    jmp .halt


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

    code_protected: ; 32-bit code segment (used when passing from real to protected)
        dw 0xffff
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0

    data_protected: ; 32-bit data segment (used when passing from real to protected)
        dw 0xffff
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

    code_real: ; 16-bit code segment (used when passing from protected to real)
        dw 0xffff
        dw 0
        db 0
        db 10011010b
        db 00001111b
        db 0

    data_real: ; 16-bit data segment (used when passing from protected to real)
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
    
RLCODE_SEG equ code_real - GDT_begin ; pointer for 16-bit CODE_SEG in GDT
RLDATA_SEG equ data_real - GDT_begin ; pointer for 16-bit DATA_SEG in GDT    
PRCODE_SEG equ code_protected - GDT_begin ; pointer for 32-bit CODE_SEG in GDT
PRDATA_SEG equ data_protected - GDT_begin ; pointer for 32-bit DATA_SEG in GDT

prot_msg: db "Successful switch to protected mode :)!", 0
real_msg: db "Successful switch back to real mode :)!", 0
times 510-($-$$) db 0 ; padding the boot sector file to be one full sector
dw 0xaa55 ; boot sector signature