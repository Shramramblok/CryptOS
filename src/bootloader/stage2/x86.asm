bits 16

section _TEXT class=CODE

; RELEVANT FOR BOTH MACROS:
; By our chosen order of the GDT table, because every descriptor in 8 bytes-
; 0x00: null descriptor
; 0x08: protected mode 32-bit code segment
; 0x10: protected mode 32-bit data segment
; 0x18: protected mode 16-bit code segment
; 0x20: protected mode 16-bit data segment


%macro x86_EnterReal 0
    [bits 32]
    ; Protected mode -> Real mode, steps are mentioned by the order of the intel manual chapter 9.9.2
    ; step 1 (disable interrupts) is already done and step 2 (disable Paging) is not relevant

    ; far jump into the 16-bit code segment (step 3)
    jmp dword 0x18:.protected_16bit

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
    [bits 16]
    ; setup segments (step 8)
    xor ax, ax
    mov ds, ax
    mov ss, ax

    ; enable interrupts (step 9)
    sti
%endmacro


%macro x86_EnterProtected 0
    [bits 16]
    ; Real mode -> Protected mode, steps are mentioned by the order of the intel manual chapter 9.9.1

    ; disable all interrupts (step 1)
    cli 
    
    ; enable A20 gateway (NOT IN MANUAL), allow us to access more than the 1MB provided in real-mode
    ; call enable_A20
    
    ; setting the GDT register to our GDT (step 2)
    ; call load_GDT

    ; set cr0 last bit to 1 to go into protected mode (step 3)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; far jump into the 32-bit code segment to perform the switch (step 4)
    jmp dword 0x08:.protected_begin

.protected_begin:
    [bits 32]
    
    ; Paging is not enabled (step 6) ,LDT is not used (step 7), Tasking is not used (step 8)
    
    ; setup segment register by the GDT (step 9), note: ES, FS, GS will stay 0 from entry label
    mov ax, 0x10 ; 32-bit DATA_SEG is the third in the GDT - offset 16
    mov ds, ax
    mov ss, ax
%endmacro


; Convert linear address (from Cpp) to Segment:Offset (realmode)
; First arg = linear address
; Second arg = target segment (SEGMENT:offset, real mode segment like es)
; Third arg = target 32-bit to use for converting the address (like eax)
; Fourth arg = target lower 16-bit of Third arg to store the offset (like ax)
; example: linear = 0x10000, segofs = 0x1000:0x0
%macro LinToSegOfs 4
    [bits 16]
    mov %3, %1
    shr %3, 4 ; upper part of %3 is not used here
    mov %2, %4
    mov %3, %1
    and %3, 0xf
%endmacro


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
; character      8 4 <-- (actually 1 byte so the value is in bp + 11)
; ------------------
global x86_RealModePutC
x86_RealModePutC:
    [bits 32]
    push ebp
    mov ebp, esp

    x86_EnterReal
    mov al, [bp + 11]
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
; drive            8 4 <-- (actually one byte so the value is in bp + 11)
; ptr_cylinders   12 4
; ptr_heads       16 4
; ptr_sectors     20 4
; ptr_driveType   24 4
; --------------------
%define drive [bp + 11]
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
; drive     8 4 <-- (actually one byte so the value is in bp + 11)
; ------------
%define drive [bp + 11]
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
; drive            8 4 <-- (actually one byte so the value is in bp + 11)
; cylinder        12 4 <-- (actually 2 bytes so the Lower is bp + 14 and Upper is bp + 15)
; head            16 4 <-- (actually one byte so the value is in bp + 19)
; sector          20 4 <-- (actually one byte so the value is in bp + 23)
; count           24 4 <-- (actually one byte so the value is in bp + 27)
; ptr_buffer      28 4
; --------------------
%define drive [bp + 11]
%define cylinderLower [bp + 14]
%define cylinderUpper [bp + 15]
%define head [bp + 19]
%define sector [bp + 23]
%define count [bp + 27]
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
; port number    8 4 <-- (actual port number is 2 bytes so it starts at bp + 10)
; value         12 4 <-- (actual value is 1 byte so it starts at bp + 15)
; ------------------
global x86_outb
x86_outb:
    [bits 32]
    mov dx, [bp + 10]
    mov al, [bp + 15]
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
; port number    8 4 <-- (actual value is 2 bytes so it starts from bp + 10)
; ------------------
global x86_inpb
x86_inpb:
    [bits 32]
    mov dx, [bp + 10]
    xor eax, eax
    in al, dx
    ret