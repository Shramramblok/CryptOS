bits 16

section .entry

extern __bss_start ; bss section symbol
extern __end ; end of sections symbol
extern DATA16_SEG
extern DATA32_SEG
extern CODE16_SEG
extern CODE32_SEG
extern cppstart
%include "protmode.asm" 
global entry
entry:
    mov [g_BootDrive], dl ; save boot drive number (will be lost in the transition)
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp
    x86_EnterProtected
; Real mode -> Protected mode, steps are mentioned by the order of the intel manual chapter 9.9.1

    ; disable all interrupts (step 1, are already disabled)
    
    ; enable A20 gateway (NOT IN MANUAL), allow us to access more than the 1MB provided in real-mode
    ;call enable_A20
    
    ; setting the GDT register to our GDT (step 2)
    ;call load_GDT

    ; set cr0 last bit to 1 to go into protected mode (step 3)
    ;mov eax, cr0
    ;or eax, 1
    ;mov cr0, eax

    ; far jump into the 32-bit code segment to perform the switch (step 4)
    ;jmp dword CODE32_SEG:.protected_begin
;.protected_begin:
    ;[bits 32]
    
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


prot_msg: db "Successful switch to protected mode :)!", 0
real_msg: db "Successful switch back to real mode :)!", 0
g_BootDrive: db 0