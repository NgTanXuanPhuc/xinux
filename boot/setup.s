[BITS 16]
[ORG 0x7E00]

main_setup:
    cld
    call init_screen

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
    call init_screen

    mov si, msg_xinux_banner_1
    call print_string

    mov si, msg_xinux_banner_2
    call print_string

    mov si, msg_xinux_banner_3
    call print_string

    mov si, msg_xinux_banner_4
    call print_string

    mov si, msg_xinux_banner_5
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
    call init_screen
    jmp main_prompt

.h_reboot:
    mov si, msg_rb
    call print_string

    db 0xEA
    dw 0
    dw 0xFFFF

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
    ; Use BIOS Disk Services (INT 0x13, AH = 0x03)
    ; to write LBA 2 (third disk sector, offset 1024)
    mov ah, 0x03              ; Write sectors function
    mov al, 0x01              ; Number of sectors to write
    mov ch, 0x00              ; Cylinder 0
    mov cl, 0x03              ; Sector 3 (LBA 2)
    mov dh, 0x00              ; Head 0
    mov dl, 0x80              ; First hard disk (Drive 0x80)
    mov bx, cmd_buf           ; Memory address containing the print command
    int 0x13

    jc .disk_write_error      ; Carry flag set means a write error occurred

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
    add si, 6                 ; Skip "print " to get the filename
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
    add si, 6                 ; Skip "print " to reach the file content
    call print_string

    mov si, nl
    call print_string

    ret

; ============================================================
; UTF-8 output
; ============================================================

print_string:
.next:
    lodsb

    test al, al
    jz .done

    ; CR
    cmp al, 0x0D
    je .newline

    ; LF
    ; CR already moves the cursor, so ignore LF.
    cmp al, 0x0A
    je .next

    ; ASCII
    cmp al, 0x80
    jb .ascii

    ; 2-byte UTF-8 sequence
    cmp al, 0xE0
    jb .utf8_2

    ; 3-byte UTF-8 sequence
    cmp al, 0xF0
    jb .utf8_3

    ; 4-byte UTF-8 is not supported by this renderer.
    jmp .unsupported

.ascii:
    call vga_put_glyph
    jmp .next

.utf8_2:
    xor bx, bx

    and al, 0x1F
    mov bl, al
    shl bx, 6

    lodsb
    and al, 0x3F

    xor ah, ah
    add bx, ax

    call unicode_to_glyph
    call vga_put_glyph

    jmp .next

.utf8_3:
    xor bx, bx

    and al, 0x0F
    mov bl, al
    shl bx, 6

    lodsb
    and al, 0x3F
    xor ah, ah
    add bx, ax

    shl bx, 6

    lodsb
    and al, 0x3F
    xor ah, ah
    add bx, ax

    call unicode_to_glyph
    call vga_put_glyph

    jmp .next

.unsupported:
    mov al, '?'
    call vga_put_glyph
    jmp .next

.newline:
    call vga_newline
    jmp .next

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

    call vga_put_glyph

    jmp .rl

.bs:
    cmp cx, 0
    jle .rl

    dec di
    dec cx

    ; Move one character backwards.
    cmp byte [cursor_x], 0
    je .rl

    dec byte [cursor_x]

    ; Erase the character.
    mov al, ' '
    call vga_put_glyph

    ; vga_put_glyph advanced one position.
    dec byte [cursor_x]

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
; ============================================================
; VGA / Unicode renderer
; ============================================================

VGA_SEGMENT equ 0xB800
FONT_SEGMENT equ 0x9000
FONT_HEIGHT equ 16

init_screen:
    ; Reset VGA text mode.
    mov ax, 0x0003
    int 0x10

    mov byte [cursor_x], 0
    mov byte [cursor_y], 0

    call init_unicode_font

    ret


; ------------------------------------------------------------
; Copy the BIOS 8x16 font to RAM and build Vietnamese glyphs.
; ------------------------------------------------------------

init_unicode_font:
    push ds
    push es
    push si
    push di
    push bp
    push bx
    push cx
    push dx

    ; BIOS: get 8x16 font address.
    mov ax, 0x1130
    mov bh, 0x06
    int 0x10

    ; BIOS returns the font in ES:BP.
    mov si, bp

    ; Destination: 9000:0000
    mov ax, FONT_SEGMENT
    mov es, ax
    xor di, di

    ; DS = BIOS font segment.
    push ds
    mov ax, es
    mov ds, ax
    ; This is only temporary; source was ES before changing ES.
    pop ds

    ; The BIOS returned ES:BP, but ES is now 9000.
    ; Retrieve the original font again.
    mov ax, 0x1130
    mov bh, 0x06
    int 0x10

    ; Source is ES:BP.
    push ds
    mov ax, es
    mov ds, ax
    mov si, bp

    ; Destination is 9000:0000.
    mov ax, FONT_SEGMENT
    mov es, ax
    xor di, di

    ; 256 glyphs * 16 bytes = 4096 bytes.
    mov cx, 2048
    rep movsw

    pop ds

    ; Build the Vietnamese glyphs.
    call build_vietnamese_font

    ; Load our modified font into VGA.
    mov ax, FONT_SEGMENT
    mov es, ax
    xor bp, bp

    mov ax, 0x1110
    mov bh, 16
    mov bl, 0
    mov cx, 256
    xor dx, dx
    int 0x10

    pop dx
    pop cx
    pop bx
    pop bp
    pop di
    pop si
    pop es
    pop ds

    ret


; ------------------------------------------------------------
; Copy an ASCII glyph and add Vietnamese marks.
;
; Table entry:
;
;   word Unicode code point
;   byte glyph index
;   byte ASCII base character
;   byte shape
;   byte tone
;
; Shape:
;   0 = none
;   1 = breve
;   2 = circumflex
;   3 = horn
;   4 = stroke
;
; Tone:
;   0 = none
;   1 = acute
;   2 = grave
;   3 = hook
;   4 = tilde
;   5 = dot below
; ------------------------------------------------------------

build_vietnamese_font:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov si, unicode_table

    mov cx, (unicode_table_end - unicode_table) / 6

.next_glyph:
    ; --------------------------------------------------------
    ; Copy base ASCII glyph.
    ; --------------------------------------------------------

    xor ax, ax
    mov al, [si + 3]

    ; AX *= 16
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1

    mov bp, ax

    xor ax, ax
    mov al, [si + 2]

    ; AX *= 16
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1

    mov di, ax

    mov dx, 16

.copy_base:
    mov al, [es:bp]
    mov [es:di], al

    inc bp
    inc di

    dec dx
    jnz .copy_base

    ; --------------------------------------------------------
    ; Recalculate destination glyph address.
    ; --------------------------------------------------------

    xor ax, ax
    mov al, [si + 2]

    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1

    mov di, ax

    ; --------------------------------------------------------
    ; Shape.
    ; --------------------------------------------------------

    mov al, [si + 4]

    cmp al, 1
    je .breve

    cmp al, 2
    je .circumflex

    cmp al, 3
    je .horn

    cmp al, 4
    je .stroke

    jmp .tone


.breve:
    or byte [es:di + 0], 0x3C
    or byte [es:di + 1], 0x42
    jmp .tone


.circumflex:
    or byte [es:di + 0], 0x18
    or byte [es:di + 1], 0x24
    or byte [es:di + 2], 0x42
    jmp .tone


.horn:
    or byte [es:di + 0], 0x02
    or byte [es:di + 1], 0x06
    or byte [es:di + 2], 0x04
    jmp .tone


.stroke:
    ; Horizontal stroke for Đ / đ.
    or byte [es:di + 7], 0x7E
    jmp .tone


.tone:
    mov al, [si + 5]

    cmp al, 1
    je .acute

    cmp al, 2
    je .grave

    cmp al, 3
    je .hook

    cmp al, 4
    je .tilde

    cmp al, 5
    je .dot

    jmp .next


.acute:
    or byte [es:di + 0], 0x04
    or byte [es:di + 1], 0x08
    jmp .next


.grave:
    or byte [es:di + 0], 0x20
    or byte [es:di + 1], 0x10
    jmp .next


.hook:
    or byte [es:di + 0], 0x08
    or byte [es:di + 1], 0x04
    jmp .next


.tilde:
    or byte [es:di + 0], 0x24
    or byte [es:di + 1], 0x18
    jmp .next


.dot:
    or byte [es:di + 14], 0x18
    or byte [es:di + 15], 0x18


.next:
    add si, 6
    loop .next

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret


; ------------------------------------------------------------
; Unicode code point in BX.
;
; Returns:
;   AL = VGA glyph index
;
; Unsupported Unicode:
;   AL = '?'
; ------------------------------------------------------------

unicode_to_glyph:
    push bx
    push cx
    push dx
    push di

    mov dx, bx
    mov di, unicode_table

    mov cx, (unicode_table_end - unicode_table) / 6

.lookup:
    cmp dx, [di]
    je .found

    add di, 6
    loop .lookup

    mov al, '?'
    jmp .done

.found:
    mov al, [di + 2]

.done:
    pop di
    pop dx
    pop cx
    pop bx

    ret


; ------------------------------------------------------------
; Write one glyph directly to VGA text memory.
;
; AL = glyph index
; ------------------------------------------------------------

vga_put_glyph:
    push bx
    push dx
    push di
    push es

    mov ax, VGA_SEGMENT
    mov es, ax

    ; row * 160
    xor bx, bx
    mov bl, [cursor_y]

    mov dx, bx

    shl bx, 7
    shl dx, 5

    add bx, dx

    ; column * 2
    xor dx, dx
    mov dl, [cursor_x]
    shl dx, 1

    add bx, dx

    mov [es:bx], al
    mov byte [es:bx + 1], 0x07

    inc byte [cursor_x]

    cmp byte [cursor_x], 80
    jb .done

    mov byte [cursor_x], 0
    inc byte [cursor_y]

    call vga_scroll

.done:
    pop es
    pop di
    pop dx
    pop bx

    ret


vga_newline:
    mov byte [cursor_x], 0
    inc byte [cursor_y]

    call vga_scroll

    ret


vga_scroll:
    cmp byte [cursor_y], 25
    jb .done

    ; Scroll one text row upward.
    mov ax, 0x0601
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    mov byte [cursor_y], 24

.done:
    ret


cursor_x:
    db 0

cursor_y:
    db 0

; ============================================================
; Boot menu
; ============================================================

msg_grub_title:
    db 13, 10
    db "========================================================", 13, 10
    db "                    X I N U X                         ", 13, 10
    db "              XINUX Operating System                  ", 13, 10
    db "========================================================", 13, 10
    db 13, 10
    db "  Welcome to XINUX.", 13, 10
    db 13, 10
    db "  1. Start XINUX", 13, 10
    db "  2. Start XINUX in Safe Mode", 13, 10
    db 13, 10
    db "  Enter 1 for normal mode or 2 for Safe Mode.", 13, 10
    db 13, 10, 0

msg_grub_opt1:
    db "  1. Start XINUX", 13, 10, 0

msg_grub_opt2:
    db "  2. Start XINUX in Safe Mode", 13, 10, 0

msg_grub_prompt:
    db 13, 10
    db "  Select an option [1-2]: ", 0


; ============================================================
; XINUX startup screen
; ============================================================

msg_xinux_banner_1:
    db 13, 10
    db "========================================================", 13, 10
    db "                 XINUX IS STARTING                    ", 13, 10
    db "========================================================", 13, 10
    db 13, 10
    db "[+] Initializing XINUX kernel...", 13, 10
    db "[+] Initializing filesystem...", 13, 10
    db "[+] Initializing system services...", 13, 10
    db "[+] Checking system configuration...", 13, 10
    db 13, 10
    db "System initialization complete.", 13, 10
    db 13, 10, 0

msg_xinux_banner_2:
    db "XINUX Operating System v0.10", 13, 10
    db "Architecture: i386", 13, 10
    db "Filesystem: EXT2-XINUX-FS-V1", 13, 10
    db 13, 10, 0

msg_xinux_banner_3:
    db "Copyright (c) 2026 Xinux Foundation.", 13, 10
    db "All rights reserved.", 13, 10
    db 13, 10, 0

msg_xinux_banner_4:
    db "For documentation and post-installation information:", 13, 10
    db "http://xinux.22web.org/UsersGuide/PostInstallation", 13, 10
    db 13, 10, 0

msg_xinux_banner_5:
    db "XINUX is ready.", 13, 10
    db "Type 'help' to display the available commands.", 13, 10
    db 13, 10, 0


; ============================================================
; System messages
; ============================================================

msg_safe_active:
    db "[!] SAFE MODE ACTIVE: All write operations are restricted.", 13, 10, 13, 10, 0

msg_prompt_user:
    db "xinux$ ", 0

msg_prompt_root:
    db "root@xinux# ", 0

nl:
    db 13, 10, 0


; ============================================================
; Commands
; ============================================================

s_help:
    db "help", 0

s_uname:
    db "uname", 0

s_clr:
    db "clear", 0

s_reboot:
    db "reboot", 0

s_whoami:
    db "whoami", 0

s_su:
    db "su", 0

s_unsu:
    db "unsu", 0

s_adduser:
    db "adduser", 0

s_mkfs:
    db "mkfs.ext2", 0

s_ls:
    db "ls", 0

s_print_prefix:
    db "print ", 0

s_cat_prefix:
    db "cat ", 0


; ============================================================
; Command output
; ============================================================

msg_hlp:
    db "Commands: help, uname, clear, reboot, whoami, su, unsu, "
    db "adduser, mkfs.ext2, ls, print <file> <text>, cat <file>", 13, 10, 0

msg_unm:
    db "XINUX v0.10-i386 EXT2 FileSystem Edition", 13, 10, 0

msg_nf:
    db "Command not found!", 13, 10, 0

msg_rb:
    db "Rebooting...", 13, 10, 0


; ============================================================
; User and filesystem messages
; ============================================================

who_user_str:
    db "user (Standard Privilege)", 0

who_root_str:
    db "root (Superuser Privilege)", 0

msg_su_ok:
    db "Switched to root user successfully.", 13, 10, 0

msg_unsu_ok:
    db "Switched back to standard user.", 13, 10, 0

msg_adduser_u:
    db "Enter new username: ", 0

msg_adduser_ok:
    db "User stored to disk successfully!", 13, 10, 0

msg_file_saved:
    db "Data written to EXT2 filesystem successfully!", 13, 10, 0

msg_mkfs_ok:
    db "EXT2 filesystem formatted on /dev/sdb successfully!", 13, 10, 0

msg_ls_header:
    db "Files in directory (/):", 13, 10, 0

msg_cat_header:
    db "--- File Content ---", 13, 10, 0

msg_disk_err:
    db "Disk read/write error via CPU controller!", 13, 10, 0

msg_access_denied:
    db "Access Denied: System is in Safe Mode!", 13, 10, 0

msg_no_files:
    db "Error: There are no files in the directory.", 13, 10, 0


; ============================================================
; System state
; ============================================================

safe_mode_flag:
    db 0

current_privilege:
    db 0

file_exists_flag:
    db 0


; ============================================================
; Buffers
; ============================================================

cmd_buf:
    times 64 db 0

file_read_buf:
    times 64 db 0


; ============================================================
; Filesystem data
; ============================================================

section .data

ext2_superblock:
    db "EXT2-XINUX-FS-V1"
    dw 1024
    dw 0xEF53
    times 490 db 0

disk_user_storage:
    times 32 db 0