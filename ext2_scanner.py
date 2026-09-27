python3 -c '
content = """import os

def scan_xinux_data():
    # Ưu tiên quét trên file All-in-One, nếu không có thì fallback về xinux_data.img cũ
    img_path = "xinux_all_in_one.img" if os.path.exists("xinux_all_in_one.img") else "xinux_data.img"
    
    if not os.path.exists(img_path):
        print("[-] Không tìm thấy file ảnh đĩa XINUX nào để quét!")
        return

    print(f"[*] Đang quét phân vùng dữ liệu từ {{img_path}}...")
    with open(img_path, "rb") as f:
        # Nếu là file gộp All-in-One, dữ liệu lệnh print được lưu ở sector thứ 2 của setup (offset 512 + 512 = 1024 hoặc từ sector 2 tùy cách ghi)
        # Hoặc ta quét từ offset 512 (sector 1) trở đi để tìm dữ liệu
        f.seek(512)
        raw_data = f.read(1024)

    # Lọc bỏ các ký tự null padding (b\\x00)
    cleaned_data = raw_data.split(b\'\\x00\')[0].decode(\'latin1\', errors=\'ignore\').strip()

    if not cleaned_data or "XINUX" in cleaned_data or "GNU GRUB" in cleaned_data:
        # Nếu không thấy lệnh print, tìm sâu hơn trong các sector tiếp theo
        f.seek(1024)
        raw_data = f.read(512)
        cleaned_data = raw_data.split(b\'\\x00\')[0].decode(\'latin1\', errors=\'ignore\').strip()

    if not cleaned_data or "print" not in cleaned_data:
        print("Error: There are no files in the dictionary.")
        return

    # Phân tích cú pháp lệnh dạng: print filename.ext content_text
    parts = cleaned_data.split(" ", 2)
    if len(parts) >= 2 and parts[0] == "print":
        full_filename = parts[1]
        file_content = parts[2] if len(parts) > 2 else ""

        # Tách tên và đuôi file (extension)
        filename_only, file_ext = os.path.splitext(full_filename)

        print("\\n================ XINUX FILE SYSTEM EXPORT ================")
        print(f" [+] Tên gốc đầy đủ : {full_filename}")
        print(f" [+] Tên tệp (Name) : {filename_only}")
        print(f" [+] Phần mở rộng   : {file_ext if file_ext else \'(Không có đuôi)\'}")
        print(f" [+] Nội dung tệp   : {file_content}")
        print("==========================================================")
    else:
        print("Error: There are no files in the dictionary.")

if __name__ == "__main__":
    scan_xinux_data()
"""
with open("tools/ext2_scanner.py", "w") as f:
    f.write(content)
print("[+] Đã cập nhật xong tools/ext2_scanner.py thông minh hơn!")
'

