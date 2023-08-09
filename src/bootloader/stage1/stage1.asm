org 0x7c00
bits 16

%define ENDL 0x0D, 0x0A

%define LOG2_OF_BLOCK_GROUP_DESCRIPTOR_SIZE 5 ; 2^5 = 32 block group descriptors size

%define STAGE2_SEGMENT 0x0
%define STAGE2_OFFSET 0x500

main:
    ; setup data segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7c00

    mov [drive_number], dl ; save drive number

    mov si, booting_msg ; si = booting_msg
    call print ; print(booting_msg)

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

    mov cx, [buffer + 20]
    inc cx
    mov [block_group_descriptor_table], cx

    cmp byte [major_version], 0
    je .version0
        mov ax, word [buffer + 88]
        mov [inode_size], ax
        jmp .finish_version_check
    .version0:
        mov word [inode_size], 128
    .finish_version_check:

    mov ax, 2 ; (root inode)
    mov bx, buffer ; buffer to read block to
    call read_inode ; read_inode(inode_number, buffer)
    mov ax, [buffer + si + 40]
    mov bx, buffer ; buffer to read block to
    call read_block ; read_block(block_number, buffer)

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
        jmp stage2_file_not_found_error ; stage2 file not found
    .found_stage2_file:
        mov ax, [bx + buffer] ; ax = inode number
        mov bx, buffer ; buffer to read block to
        call read_inode ; read_inode(inode_number, buffer)

        mov ax, [buffer + si + 40]
        call read_block ; read_block(block_number, buffer)

        mov ax, STAGE2_SEGMENT
        mov ds, ax
        mov es, ax

        jmp STAGE2_SEGMENT:STAGE2_OFFSET ; here the stage2 starts


read_disk_error:
    mov si, read_disk_error_msg ; si = str
    call print ; print(str)
    jmp wait_for_key_and_reboot

reset_disk_error:
    mov si, reset_disk_error_msg ; si = str
    call print ; print(str)
    jmp wait_for_key_and_reboot

stage2_file_not_found_error:
    mov si, stage2_file_not_found_msg ; si = str
    call print ; print(str)
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
    .print_loop:
    lodsb ; al = [si], si++
    or al, al ; al == 0?
    jz .done_print ; yes, done

    xor bh, bh ; page 0
    mov ah, 0x0e ; tty mode
    int 0x10 ; print al

    jmp .print_loop ; print next char
    .done_print:
        ;pop cx ; restore cx
        pop ax ; restore ax
        pop si ; restore si
    ret ; return

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
    div word [heads] ; ax = lba / sectors_per_track / heads, dx = (lba / sectors_per_track) % heads
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
; es:bx = buffer for data read from the disk

;BLOCK_GROUP_DESCRIPTOR_TABLE_INDEX = ((inode – 1) / INODES_PER_GROUP)
;(((inode – 1) % INODES_PER_GROUP) * INODE_SIZE) / BLOCK_SIZE
;INODE_OFFSET = ((inode – 1) % INODES_PER_GROUP) % BLOCKS_PER_GROUP * INODE_SIZE
; si = offset of inode in buffer
read_inode:
    push ax ; save ax
    push cx ; save cx
    push dx ; save dx

    mov dx, ax ; save ax
    mov ax, word [block_group_descriptor_table] ; save block group descriptor table address
    call read_block ; read_block(block_number, buffer)
    mov ax, dx ; restore ax

    xor dx, dx ; dx = 0
    dec ax ; ax--
    div word [inodes_per_group] ; ax = ax / inodes_per_group, dx = ax % inodes_per_group
    push dx ; save dx (index)

    mov si, ax ; si = block group block number or index
    shl si, LOG2_OF_BLOCK_GROUP_DESCRIPTOR_SIZE ; ax = ax * 32

    mov cx, [si + buffer + 8] ; ax = start block of inode table    

    mov ax, dx ; ax = index
    xor dx, dx ; dx = 0
    div word [blocks_per_group] ; ax = ax / blocks_per_group, dx = ax % blocks_per_group
    mov ax, dx ; ax = inode index in block
    mul word [inode_size] ; ax = ax * inode_size
    mov si, ax ; offset of inode in block

    pop dx ; restore dx
    mov ax, dx ; ax = index
    mul word [inode_size] ; ax = ax * inode_size
    div word [block_size] ; ax = ax / block_size = containing block

    add ax, cx ; ax = containing block + start block of inode table

    call read_block ; read_block(block_number, buffer)
    
    pop dx ; restore dx
    pop cx ; restore cx
    pop ax ; restore ax

    ret

; data
booting_msg: db "Booting...", ENDL, 0
read_disk_error_msg: db "Failed to read disk!", ENDL, 0
reset_disk_error_msg: db "Failed to reset disk!", ENDL, 0
stage2_file_not_found_msg:
stage2_file_name: db "stage2.bin"
db " not found!", ENDL, 0
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
;new_segment: dw 0 ; will be filled in at run time
times 510-($-$$) db 0
dw 0xaa55
buffer: ; buffer for disk_read