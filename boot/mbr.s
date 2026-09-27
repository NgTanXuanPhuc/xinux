[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Đọc setup.bin từ sector 2 vào RAM tại 0x7E00
    mov ah, 0x02
    mov al, 20          ; Đọc 20 sectors chứa setup
    mov ch, 0
    mov dh, 0
    mov cl, 2           ; Bắt đầu từ sector 2
    mov dl, 0x80        ; Ổ đĩa chính (sda)
    mov bx, 0x7E00
    int 0x13
    jc disk_error

    jmp 0x0000:0x7E00

disk_error:
    jmp $

times 510-($-$$) db 0
dw 0xAA55
