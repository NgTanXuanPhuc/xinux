[org 0x7c00]
[bits 16]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Lưu tên thiết bị từ BIOS vào địa chỉ 0x90500 để Kernel dùng
    mov si, bios_device_name
    mov di, 0x90500
.copy_bios:
    lodsb
    stosb
    test al, al
    jnz .copy_bios

    ; Đọc Kernel từ ổ đĩa (Sector 2, đọc 30 sectors vào 0x1000)
    mov ah, 0x02
    mov al, 30
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x1000
    int 0x13
    jc disk_error

    ; Chuyển sang Protected Mode 32-bit
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode_start

disk_error:
    jmp $

[bits 32]
protected_mode_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    jmp 0x1000                  ; Nhảy vào nhân kernel.s tại 0x1000

bios_device_name db 'Xinux-VM-Box', 0

gdt_start:
    dq 0
gdt_code:
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
gdt_data:
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55
