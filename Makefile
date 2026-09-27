ASM = nasm
PYTHON = python3
QEMU = qemu-system-i386

all: build allinone

build: boot/mbr.bin boot/setup.bin xinux_disk.img xinux_data.img
	@echo "[+] Biên dịch và đóng gói hệ thống XINUX thành công!"

boot/mbr.bin: boot/mbr.s
	$(ASM) -f bin boot/mbr.s -o boot/mbr.bin

boot/setup.bin: boot/setup.s
	$(ASM) -f bin boot/setup.s -o boot/setup.bin

xinux_disk.img:
	$(PYTHON) tools/mkfs_qemu.py 2>/dev/null || $(PYTHON) -c 'with open("xinux_disk.img", "wb") as f: f.write(b"\x00" * (10 * 1024 * 1024))'
	@if [ -f boot/mbr.bin ]; then dd if=boot/mbr.bin of=xinux_disk.img conv=notrunc bs=512 count=1 2>/dev/null; fi
	@if [ -f boot/setup.bin ]; then dd if=boot/setup.bin of=xinux_disk.img conv=notrunc bs=512 seek=1 2>/dev/null; fi

xinux_data.img:
	dd if=/dev/zero of=xinux_data.img bs=1M count=2 2>/dev/null

# Mục tiêu tạo file All-in-One cho Rufus
allinone: build
	$(PYTHON) tools/mkfs_all_in_one.py

qemu: build
	$(QEMU) \
		-drive format=raw,file=xinux_disk.img,index=0,media=disk \
		-drive format=raw,file=xinux_data.img,index=1,media=disk \
		-vnc :0

# Chạy QEMU với file gộp All-in-One (giống hệt cắm USB thật)
qemu-usb: allinone
	$(QEMU) \
		-drive format=raw,file=xinux_all_in_one.img,media=disk \
		-vnc :0

scan:
	$(PYTHON) tools/ext2_scanner.py

clean:
	rm -f boot/*.bin *.img
	@echo "[+] Đã dọn dẹp sạch sẽ các file binary và ổ đĩa ảo!"

.PHONY: all build allinone qemu qemu-usb scan clean
