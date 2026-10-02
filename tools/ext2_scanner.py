import os

def scan_xinux_data():

    img_path = "xinux_all_in_one.img" if os.path.exists("xinux_all_in_one.img") else "xinux_data.img"

    if not os.path.exists(img_path):

        print("[-] No system disk image file found to scan!")

        return

    print(f"[*] Scanning the data partition from: {img_path}...")

    with open(img_path, "rb") as f:

        if img_path == "xinux_all_in_one.img":

            f.seek(1024)

        else:

            f.seek(512)

        raw_data = f.read(512)

    cleaned_data = raw_data.split(b'\x00')[0].decode('latin1', errors='ignore').strip()

    if not cleaned_data or "print" not in cleaned_data:

        print("Error: There are no files in the directory.")

        return

    parts = cleaned_data.split(" ", 2)

    if len(parts) >= 2 and parts[0] == "print":

        full_filename = parts[1]

        file_content = parts[2] if len(parts) > 2 else ""

        filename_only, file_ext = os.path.splitext(full_filename)

        print("\n================ XINUX FILE SYSTEM EXPORT ================")

        print(f" [+] Disk image source : {img_path}")

        print(f" [+] Full original name : {full_filename}")

        print(f" [+] Filename (Name)    : {filename_only}")

        print(f" [+] Extension           : {file_ext if file_ext else '(No extension)'}")

        print(f" [+] File content        : {file_content}")

        print("==========================================================")

    else:

        print(f"[*] Raw data in sector: {cleaned_data}")

if __name__ == "__main__":

    scan_xinux_data()