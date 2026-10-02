[org 0x7c00]
[bits 16]

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x8000 ; Place the initial stack at 0x8000

    ; Save the kernel name at physical address 0x90500 using ES:DI addressing
    mov ax, 0x9000
    mov es, ax
    mov di, 0x0500
    mov si, kernel_name
    cld

.copy_bios:
    lodsb
    stosb
    test al, al
    jnz .copy_bios

    ; Read the kernel from the disk
    mov ax, 0
    mov es, ax
    mov ah, 0x02
    mov al, 30
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x1000
    int 0x13
    jc disk_error

    ; Switch to 32-bit Protected Mode
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

    jmp 0x1000 ; Jump to kernel loaded at 0x1000

kernel_name db 'Xinux-VM-Box', 0

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
