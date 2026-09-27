import os

with open("xinux_disk.img", "wb") as f:
    f.write(b"\x00" * (10 * 1024 * 1024))
print("[+] Đã khởi tạo xinux_disk.img thành công!")
