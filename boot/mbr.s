[BITS 16]
[ORG 0x7C00]

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x8000
    cld

    ; Read setup.bin from sector 2 into RAM at 0x7E00
    mov ah, 0x02
    mov al, 20          ; Read 20 sectors containing setup
    mov ch, 0
    mov dh, 0
    mov cl, 2           ; Start from sector 2
    mov dl, 0x80        ; Primary disk (sda)
    mov bx, 0x7E00
    int 0x13
    jc disk_error

    jmp 0x0000:0x7E00

disk_error:
    jmp $

times 510-($-$$) db 0
dw 0xAA55