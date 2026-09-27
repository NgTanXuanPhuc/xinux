[BITS 16]
[ORG 0x7E00]

main_setup:
    mov ax, 0x0003
    int 0x10                  ; Xóa màn hình Text mode

grub_menu:
    mov si, msg_grub_title
    call print_string
    mov si, msg_grub_opt1
    call print_string
    mov si, msg_grub_opt2
    call print_string
    mov si, msg_grub_prompt
    call print_string

.wait_choice:
    mov ah, 0
    int 0x16
    cmp al, '1'
    je .boot_normal
    cmp al, '2'
    je .boot_safe
    jmp .wait_choice

.boot_normal:
    mov byte [safe_mode_flag], 0
    jmp start_loading

.boot_safe:
    mov byte [safe_mode_flag], 1
    jmp start_loading

start_loading:
    mov ax, 0x0003
    int 0x10

    mov si, msg_minix_banner_1
    call print_string
    mov si, msg_minix_banner_2
    call print_string
    mov si, msg_minix_banner_3
    call print_string
    mov si, msg_minix_banner_4
    call print_string
    mov si, msg_minix_banner_5
    call print_string
    
    call delay_20_seconds

    cmp byte [safe_mode_flag], 1
    jne main_prompt
    mov si, msg_safe_active
    call print_string

main_prompt:
    mov al, [current_privilege]
    cmp al, 1
    je .prompt_root
    mov si, msg_prompt_user
    jmp .do_prompt
.prompt_root:
    mov si, msg_prompt_root

.do_prompt:
    call print_string

    mov di, cmd_buf
    call read_line

    mov esi, cmd_buf
    mov edi, s_help
    call str_cmp
    jc .h_help

    mov esi, cmd_buf
    mov edi, s_uname
    call str_cmp
    jc .h_uname

    mov esi, cmd_buf
    mov edi, s_clr
    call str_cmp
    jc .h_clr

    mov esi, cmd_buf
    mov edi, s_reboot
    call str_cmp
    jc .h_reboot

    mov esi, cmd_buf
    mov edi, s_whoami
    call str_cmp
    jc .h_whoami

    mov esi, cmd_buf
    mov edi, s_su
    call str_cmp
    jc .h_su

    mov esi, cmd_buf
    mov edi, s_unsu
    call str_cmp
    jc .h_unsu

    mov esi, cmd_buf
    mov edi, s_adduser
    call str_cmp
    jc .h_adduser

    mov esi, cmd_buf
    mov edi, s_mkfs
    call str_cmp
    jc .h_mkfs

    mov esi, cmd_buf
    mov edi, s_ls
    call str_cmp
    jc .h_ls

    mov esi, cmd_buf
    mov edi, s_print_prefix
    call str_ncmp
    jc .h_print

    mov esi, cmd_buf
    mov edi, s_cat_prefix
    call str_ncmp
    jc .h_cat

    cmp byte [cmd_buf], 0
    je main_prompt

    mov si, msg_nf
    call print_string
    jmp main_prompt

.h_help:
    mov si, msg_hlp
    call print_string
    jmp main_prompt

.h_uname:
    mov si, msg_unm
    call print_string
    jmp main_prompt

.h_clr:
    mov ax, 0x0003
    int 0x10
    jmp main_prompt

.h_reboot:
    mov si, msg_rb
    call print_string
    db 0xEA
    dw 0, 0xFFFF

.h_whoami:
    mov al, [current_privilege]
    cmp al, 1
    je .who_root
    mov si, who_user_str
    jmp .who_done
.who_root:
    mov si, who_root_str
.who_done:
    call print_string
    mov si, nl
    call print_string
    jmp main_prompt

.h_su:
    mov byte [current_privilege], 1
    mov si, msg_su_ok
    call print_string
    jmp main_prompt

.h_unsu:
    mov byte [current_privilege], 0
    mov si, msg_unsu_ok
    call print_string
    jmp main_prompt

.h_adduser:
    cmp byte [safe_mode_flag], 1
    je .access_denied_err
    mov si, msg_adduser_u
    call print_string
    mov di, disk_user_storage
    call read_line
    mov si, msg_adduser_ok
    call print_string
    jmp main_prompt

.h_mkfs:
    cmp byte [safe_mode_flag], 1
    je .access_denied_err
    call ext2_format_disk
    mov si, msg_mkfs_ok
    call print_string
    jmp main_prompt

.h_ls:
    call ext2_read_dir
    jmp main_prompt

.h_print:
    cmp byte [safe_mode_flag], 1
    je .access_denied_err
    
    mov byte [file_exists_flag], 1
    call ext2_write_file
    mov si, msg_file_saved
    call print_string
    jmp main_prompt

.h_cat:
    cmp byte [file_exists_flag], 0
    je .no_files_error
    call ext2_read_file_content
    jmp main_prompt

.no_files_error:
    mov si, msg_no_files
    call print_string
    jmp main_prompt

.access_denied_err:
    mov si, msg_access_denied
    call print_string
    jmp main_prompt

ext2_format_disk:
    mov byte [file_exists_flag], 0
    ret

ext2_write_file:
    ; Sử dụng BIOS Disk Services (INT 0x13, AH = 0x03) để ghi LBA 2 (Sector thứ 3 của ổ đĩa, tương ứng offset 1024)
    mov ah, 0x03              ; Write sectors function
    mov al, 0x01              ; Số lượng sector ghi (1 sector = 512 bytes)
    mov ch, 0x00              ; Cylinder 0
    mov cl, 0x03              ; Sector số 3 (LBA 2)
    mov dh, 0x00              ; Head 0
    mov dl, 0x80              ; Ổ cứng đầu tiên (Drive 0x80)
    mov bx, cmd_buf           ; Địa chỉ vùng nhớ chứa chuỗi lệnh print cần ghi
    int 0x13
    jc .disk_write_error      ; Nếu cờ Carry bật lên nghĩa là ghi lỗi
    ret

.disk_write_error:
    mov si, msg_disk_err
    call print_string
    ret

ext2_read_dir:
    cmp byte [file_exists_flag], 0
    je .no_files_error_ls

    mov si, msg_ls_header
    call print_string
    
    mov si, cmd_buf
    add si, 6           ; Bỏ qua chữ "print " để lấy tên file hiển thị
    call print_string
    mov si, nl
    call print_string
    ret

.no_files_error_ls:
    mov si, msg_no_files
    call print_string
    ret

ext2_read_file_content:
    mov si, msg_cat_header
    call print_string
    mov si, cmd_buf
    add si, 6           ; In nội dung file
    call print_string
    mov si, nl
    call print_string
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

read_line:
    xor cx, cx
.rl:
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .ent
    cmp al, 0x08
    je .bs
    cmp cx, 62
    jge .rl
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .rl
.bs:
    cmp cx, 0
    jle .rl
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .rl
.ent:
    mov byte [di], 0
    mov si, nl
    call print_string
    ret

str_cmp:
    push esi
    push edi
.sc_l:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .sc_no
    test al, al
    jz .sc_ok
    inc esi
    inc edi
    jmp .sc_l
.sc_ok:
    pop edi
    pop esi
    stc
    ret
.sc_no:
    pop edi
    pop esi
    clc
    ret

str_ncmp:
    push esi
    push edi
.snc_l:
    mov bl, [edi]
    test bl, bl
    jz .snc_ok
    mov al, [esi]
    cmp al, bl
    jne .snc_no
    inc esi
    inc edi
    jmp .snc_l
.snc_ok:
    pop edi
    pop esi
    stc
    ret
.snc_no:
    pop edi
    pop esi
    clc
    ret

delay_20_seconds:
    mov dx, 1
.dl_outer:
    mov cx, 0x1000
.dl_inner:
    dec cx
    jnz .dl_inner
    dec dx
    jnz .dl_outer
    ret

msg_grub_title    db "GNU GRUB  version 2.06-XINUX", 13, 10, 13, 10
                  db "  Use the up and down arrows to select, then press enter.", 13, 10
                  db "--------------------------------------------------------", 13, 10, 0
msg_grub_opt1     db "  * 1. XINUX (Normal Mode)", 13, 10, 0
msg_grub_opt2     db "    2. XINUX Safe Mode", 13, 10, 13, 10, 0
msg_grub_prompt   db "Select option [1-2]: ", 0

msg_minix_banner_1 db "The system is now running and many commands work normally.  To use XINUX", 13, 10
                   db "in a serious way, you need to install it to your hard disk.", 13, 10, 13, 10, 0
msg_minix_banner_2 db "Copyright (c) 2026 Xinux Foundation. All rights reserved.", 13, 10
                   db "The Xinux Foundation, Inc.", 13, 10, 0
msg_minix_banner_3 db "Architectural design inspired by classical UNIX & EXT2 file systems.", 13, 10, 13, 10, 0
msg_minix_banner_4 db "For post-installation usage tips and package management, please see:", 13, 10
                   db "http://xinux.22web.org/UsersGuide/PostInstallation", 13, 10, 13, 10, 0
msg_minix_banner_5 db "We'd like your feedback: http://xinux.22web.org/community/", 13, 10, 13, 10, 0

msg_safe_active   db "[!] SAFE MODE ACTIVE: All write operations are restricted.", 13, 10, 13, 10, 0

msg_prompt_user   db "# ", 0
msg_prompt_root   db "root# ", 0
nl                db 13, 10, 0

s_help            db "help", 0
s_uname           db "uname", 0
s_clr             db "clear", 0
s_reboot          db "reboot", 0
s_whoami          db "whoami", 0
s_su              db "su", 0
s_unsu            db "unsu", 0
s_adduser         db "adduser", 0
s_mkfs            db "mkfs.ext2", 0
s_ls              db "ls", 0
s_print_prefix    db "print ", 0
s_cat_prefix      db "cat ", 0

msg_hlp           db "Commands: help, uname, clear, reboot, whoami, su, unsu, adduser, mkfs.ext2, ls, print <file> <text>, cat <file>", 13, 10, 0
msg_unm           db "XINUX v0.10-i386 EXT2 FileSystem Edition", 13, 10, 0
msg_nf            db "Command not found!", 13, 10, 0
msg_rb            db "Rebooting...", 13, 10, 0

who_user_str      db "user (Standard Privilege)", 0
who_root_str      db "root (Superuser Privilege)", 0
msg_su_ok         db "Switched to root user successfully.", 13, 10, 0
msg_unsu_ok       db "Switched back to standard user.", 13, 10, 0

msg_adduser_u     db "Enter new username: ", 0
msg_adduser_ok    db "User stored to disk successfully!", 13, 10, 0
msg_file_saved    db "Data written to EXT2 filesystem successfully!", 13, 10, 0
msg_mkfs_ok       db "Filesystem EXT2 formatted on /dev/sdb successfully!", 13, 10, 0
msg_ls_header     db "Files in dictionary (/):", 13, 10, 0
msg_cat_header    db "--- File Content ---", 13, 10, 0
msg_disk_err      db "Disk read/write error via CPU controller!", 13, 10, 0
msg_access_denied db "Access Denied: System is in Safe Mode!", 13, 10, 0
msg_no_files      db "Error: There are no files in the dictionary.", 13, 10, 0

safe_mode_flag    db 0
current_privilege db 0
file_exists_flag  db 0

cmd_buf           times 64 db 0
file_read_buf     times 64 db 0

section .data
ext2_superblock   db "EXT2-XINUX-FS-V1"
                  dw 1024
                  dw 0xEF53
                  times 490 db 0

disk_user_storage times 32 db 0
