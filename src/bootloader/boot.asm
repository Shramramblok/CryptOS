org 0x7c00
bits 16

%define ENDL 0x0D, 0x0A

%define LOG2_OF_BLOCK_GROUP_DESCRIPTOR_SIZE 5 ; 2^5 = 32 block group descriptors size

%macro print$ 1
    push si ; save si
    push cx ; save cx
    xor cx, cx ; cx = 0
    mov si, %1 ; si = str
    call print ; print(str)
    pop cx ; restore cx
    pop si ; restore si
%endmacro

%macro printsize$ 2
    push si ; save si
    push cx ; save cx
    mov cx, %2 ; cx = length
    mov si, %1 ; si = str
    call print ; print(str)
    pop cx ; restore cx
    pop si ; restore si
%endmacro

%macro printint$ 1
    push ax ; save ax
    mov ax, %1 ; ax = int
    call printint ; printint(int)
    pop ax ; restore ax
%endmacro

%macro lba2chs$ 1
    push ax ; save ax
    mov ax, %1 ; ax = lba
    call lba2chs ; lba2chs(lba)
    pop ax ; restore ax
%endmacro

main:
    ; setup data segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7c00

    mov [drive_number], dl ; save drive number

    ; read third sector of disk
    mov ax, 2 ; third sector
    mov cl, 1 ; read 1 sector 
    mov bx, buffer ; buffer to read sector to
    call disk_read ; disk_read(lba, sectors, drive, buffer)

    mov cl, [buffer + 24]
    shl word [block_size], cl ; calculate block size
    inc cl
    mov byte [shl_sectors_per_block], cl

    mov cx, [buffer + 40]
    mov [inodes_per_group], cx

    mov cx, [buffer + 32]
    mov [blocks_per_group], cx

    mov cx, [buffer + 76]
    mov [major_version], cx

    cmp byte [major_version], 0
    je .version0
        mov ax, word [buffer + 88]
        mov [inode_size], ax
        jmp .finish_version_check
    .version0:
        mov word [inode_size], 128
    .finish_version_check:
    
    cmp byte [shl_sectors_per_block], 0
    je .second_block_group_descriptor_table
        mov ax, 1 ; (second block)
        jmp .read_group_descriptor_table
    .second_block_group_descriptor_table:
        mov ax, 2 ; (third block)
    .read_group_descriptor_table:

    mov word [block_group_descriptor_table], ax ; save block group descriptor table address
    mov bx, buffer ; buffer to read block to
    call read_block ; read_block(block_number, buffer)

    mov ax, 2
    call set_inode_first_data_in_buffer ; set_inode_first_data_in_buffer(inode_number)

    xor bx, bx ; bx = 0
    xor cx, cx ; cx = 0
    .read_root_dir:
        mov di, stage2_file_name ; si = stage2_file_name
        mov cl, [bx + buffer + 6]
        mov si, bx ; si = directory entry
        add si, buffer ; si = directory entry + buffer
        add si, 8 ; si = directory entry + buffer + 8
        repe cmpsb ; compare [si], [di], si++, di++, cx--
        je .found_stage2_file ; found stage2 file
        add bx, [bx + buffer + 4] ; bx += directory entry size
        cmp word [bx + buffer + 4], 0 ; directory entry size == 0?
        jnz .read_root_dir ; directory entery size != 0, read next directory entry
        jmp halt
    .found_stage2_file:
        mov ax, [bx + buffer] ; ax = directory entry->inode
        call set_inode_first_data_in_buffer ; set_inode_first_data_in_buffer(inode_number)
        ;printint$ [buffer]


read_disk_error:
    print$ read_disk_error_msg
    jmp wait_for_key_and_reboot

reset_disk_error:
    ;print$ reset_disk_error_msg
    jmp wait_for_key_and_reboot

wait_for_key_and_reboot:
    mov ah, 0
    int 0x16 ; wait for key
    jmp 0xFFFF:0x0000 ; here the BIOS starts

halt:
    cli
    hlt

; si = pointer to string
; cx = length of string (if 0, string is null terminated)
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

; ax = int
printint:
    push ax ; save ax
    push bx ; save bx
    push cx ; save cx
    push dx ; save dx

    mov bx, 10 ; bx = 10
    xor cx, cx ; cx = 0
    .loop:
        xor dx, dx ; dx = 0
        div bx ; ax = ax / bx, dx = ax % bx
        push dx ; push dx to stack
        inc cx ; cx++
        test ax, ax ; ax == 0?
        jnz .loop ; no, loop

    .print:
        pop ax ; pop dx from stack
        xor bh, bh ; page 0
        add al, '0' ; al += '0'
        mov ah, 0x0e ; tty mode
        int 0x10 ; print al
        loop .print ; cx != 0, loop

        mov al, ' ' ; al += '0'
        mov ah, 0x0e ; tty mode
        int 0x10 ; print al

    pop dx ; restore dx
    pop cx ; restore cx
    pop bx ; restore bx
    pop ax ; restore ax
    ret

; convert chs to lba
; chs: cylinder (starts from 0), head (starts from 0), sector (starts from 1)
; lba: linear block address (starts from 0)
; ax = lba, cx = cylinder, dh = head, cl = sector

;def lba2chs(lba):
;    lba, sector = divmod(lba, sectors_per_track)
;    sector += 1
;    lba, head = divmod(lba, heads)
;    return lba, head, sector

lba2chs:
    push ax ; save ax
    push dx ; save dx

    xor dx, dx ; dx = 0
    div word [sectors_per_track] ; ax = lba / sectors_per_track, dx = lba % sectors_per_track
    inc dx ; dx = lba % sectors_per_track + 1
    mov cx, dx ; cx = sector
    xor dx, dx ; dx = 0
    div dword [heads] ; ax = lba / sectors_per_track / heads, dx = (lba / sectors_per_track) % heads
    mov dh, dl ; dh = head
    mov ch, al ; cl = cylinder
    shl ah, 6 ; ah = cylinder >> 2
    or cl, ah ; cl = cylinder >> 2 | cylinder

    pop ax
    mov dl, al
    pop ax

    ret

; ax = lba
; cl = number of sectors to read
; dl = drive number
; es:bx = buffer for data read from the disk
disk_read:
    push ax ; save ax
    push bx ; save bx
    push cx ; save cx
    push dx ; save dx
    push di ; save di

    push cx ; save cx (number of sectors to read)
    call lba2chs ; lba2chs(lba)
    pop ax ; restore cx (number of sectors to read)

    mov ah, 0x02 ; read sectors
    mov di, 3 ; retry 3 times

    .try_disk_read:
        pusha ; save all registers, because we don't know what int 13h (BIOS) will overwrite
        stc ; set carry flag, to check if int 13h failed (some BIOS implementations don't set carry flag on error)
        int 13h ; read sectors
        jnc .disk_read_ok ; no error, read successful

        popa ; restore all registers
        call reset_disk ; reset disk

        dec di ; di--
        jnz .try_disk_read ; di != 0, retry
    
    .disk_read_fail:
        jmp read_disk_error ; failed to read, print error message and halt


    .disk_read_ok:
        popa ; restore all registers

        pop di ; restore di
        pop dx ; restore dx
        pop cx ; restore cx
        pop bx ; restore bx
        pop ax ; restore ax

        ret

; dl = drive number
reset_disk:
    pusha ; save all registers, because we don't know what int 13h (BIOS) will overwrite
    xor ah, ah ; reset disk
    stc ; set carry flag, to check if int 13h failed (some BIOS implementations don't set carry flag on error)
    int 13h ; reset disk
    jc reset_disk_error ; failed to reset disk, print error message and halt
    popa ; restore all registers
    ret

; ax = block number
; es:bx = buffer for data read from the disk
read_block:
    push ax ; save ax
    push cx ; save cx
    push dx ; save dx

    mov cl, [shl_sectors_per_block]
    shl ax, cl ; ax = ax * sectors_per_block
    mov dx, 1
    shl dx, cl ; dx = sectors_per_block
    mov cx, dx ; cx = sectors_per_block
    mov dl, [drive_number] ; dl = drive_number

    call disk_read

    pop dx ; restore dx
    pop cx ; restore cx
    pop ax ; restore ax

    ret


; ax = inode number
set_inode_first_data_in_buffer:
    push ax ; save ax
    push bx ; save bx
    push cx ; save cx
    push dx ; save dx

    dec ax ; ax--
    div word [inodes_per_group] ; ax = ax / inodes_per_group, dx = ax % inodes_per_group
    
    mov bx, ax ; bx = block group
    shl bx, LOG2_OF_BLOCK_GROUP_DESCRIPTOR_SIZE ; bx = bx * 32
    mov cx, [bx + buffer + 8] ; ax = start block of inode table

    mov ax, dx ; ax = index
    mul word [inode_size] ; ax = ax * inode_size
    mov si, ax ; si = ax * inode_size
    div word [block_size] ; ax = ax / block_size = containing block
    add ax, cx ; ax = containing block + start block of inode table
    printint$ ax
    mov bx, buffer ; buffer to read block to
    call read_block ; read_block(block_number, buffer)
    
    mov ax, [buffer + si + 40] ; ax = root inode->driect pointer 0 (contents of root directory)
    mov bx, buffer ; buffer to read block to
    call read_block ; read_block(block_number, buffer)

    pop dx ; restore dx
    pop cx ; restore cx
    pop bx ; restore bx
    pop ax ; restore ax

    ret

; data
msg: db "Hello, World!", ENDL, 0
read_disk_error_msg: db "Failed to read disk!", ENDL, 0
reset_disk_error_msg: db "Failed to reset disk!", ENDL, 0
sectors_per_track: dw 18
drive_number: db 0 ; will be filled in at run time
heads: dw 2
shl_sectors_per_block: db 0 ; will be filled in at run time
block_size: dw 0x400 ; 1024 bytes (will be filled in at run time)
blocks_per_group: dw 0 ; will be filled in at run time
inodes_per_group: dw 0 ; will be filled in at run time
major_version: db 0 ; will be filled in at run time
inode_size: dw 0 ; will be filled in at run time
block_group_descriptor_table: dw 0 ; will be filled in at run time
stage2_file_name: db "stage2.bin"
times 510-($-$$) db 0
dw 0xaa55
buffer: ; buffer for disk_read