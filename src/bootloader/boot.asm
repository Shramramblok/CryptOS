org 0x7c00
bits 16

%define ENDL 0x0D, 0x0A

%macro print$ 1
    mov si, %1 ; si = str
    call print ; print(str)
%endmacro

%macro printint$ 1
    mov ax, %1 ; ax = int
    call printint ; printint(int)
%endmacro

%macro lba2chs$ 1
    mov ax, %1 ; ax = lba
    call lba2chs ; lba2chs(lba)
%endmacro

; FAT12 header
jmp short main
nop

bdb_oem: db "MSWIN4.1"
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0xE0
bdb_total_sectors: dw 2880
bdb_media_descriptor_type: db 0xF0
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sectors: dd 0

; extended boot record
bdb_drive_number: db 0
bdb_reserved: db 0
bdb_boot_signature: db 0x29  ; / 0x28h
bdb_volume_id: dd 0x69696969
bdb_volume_label: db "CryptOS    "
bdb_file_system_type: db "FAT12   "

main:
    ; setup data segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7c00

    mov [bdb_drive_number], dl ; save drive number

    ; read second sector of disk
    mov ax, 1 ; lba = 1
    mov cl, 1 ; read sector 1 (second sector, starts from 0)
    mov bx, 0x7e00 ; buffer to read sector 1
    call disk_read ; disk_read(lba, sectors, drive, buffer)

    print$ msg

    jmp halt

read_disk_error:
    print$ read_disk_error_msg
    jmp wait_for_key_and_reboot

reset_disk_error:
    print$ reset_disk_error_msg
    jmp wait_for_key_and_reboot

wait_for_key_and_reboot:
    mov ah, 0
    int 0x16 ; wait for key
    jmp 0xFFFF:0x0000 ; here the BIOS starts

halt:
    cli
    hlt

; si = pointer to string
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

    jmp .print_loop ; no, print next char
    .done_print:
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
;    lba, sector = divmod(lba, bdb_sectors_per_track)
;    sector += 1
;    lba, head = divmod(lba, bdb_heads)
;    return lba, head, sector

lba2chs:
    push ax ; save ax
    push dx ; save dx

    xor dx, dx ; dx = 0
    div word [bdb_sectors_per_track] ; ax = lba / sectors_per_track, dx = lba % sectors_per_track
    inc dx ; dx = lba % sectors_per_track + 1
    mov cx, dx ; cx = sector
    xor dx, dx ; dx = 0
    div word [bdb_heads] ; ax = lba / sectors_per_track / heads, dx = (lba / sectors_per_track) % heads
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


    


msg: db "Hello, World!", ENDL, 0
read_disk_error_msg: db "Failed to read disk!", ENDL, 0
reset_disk_error_msg: db "Failed to reset disk!", ENDL, 0

times 510-($-$$) db 0
dw 0xaa55