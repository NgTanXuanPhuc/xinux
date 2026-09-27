import os

def build_all_in_one():
    output_img = "xinux_all_in_one.img"
    mbr_path = "boot/mbr.bin"
    setup_path = "boot/setup.bin"

    if not os.path.exists(mbr_path) or not os.path.exists(setup_path):
        print("[-] Lỗi: Chưa biên dịch mbr.bin hoặc setup.bin! Hãy chạy make trước.")
        return

    # Tạo một file ảnh tổng dung lượng 12MB (đủ chỗ cho cả OS lẫn Data)
    total_size = 12 * 1024 * 1024
    print("[*] Đang khởi tạo image All-in-One (12MB)...")
    
    with open(output_img, "wb") as f:
        # Ghi toàn bộ khoảng trống 0x00
        f.write(b"\x00" * total_size)

    # Nạp MBR vào sector 0 (offset 0)
    with open(output_img, "r+b") as f:
        with open(mbr_path, "rb") as mbr:
            f.seek(0)
            f.write(mbr.read())

        # Nạp Setup vào sector 1 (offset 512 bytes)
        with open(setup_path, "rb") as setup:
            f.seek(512)
            f.write(setup.read())

    print(f"[+] Đã đóng gói thành công thành file: {output_img}")
    print(f"[+] Bây giờ ông có thể dùng Rufus nạp file {output_img} vào USB để chạy trên máy thật ngon lành!")

if __name__ == "__main__":
    build_all_in_one()
