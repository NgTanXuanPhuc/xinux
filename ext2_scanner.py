```text
python3 -c '
content = """import os
def scan_xinux_data():

# Prioritize scanning the All-in-One file; if it does not exist, fall back to the old xinux_data.img

img_path = "xinux_all_in_one.img" if os.path.exists("xinux_all_in_one.img") else "xinux_data.img"

if not os.path.exists(img_path):

    print("[-] No XINUX disk image file found to scan!")

    return

print(f"[*] Scanning the data partition from {img_path}...")

with open(img_path, "rb") as f:

    # If this is an All-in-One file, print command data is stored in the second sector of setup (offset 512 + 512 = 1024, or starting from sector 2 depending on how it was written)

    # Alternatively, scan from offset 512 (sector 1) onward to find the data

    f.seek(512)

    raw_data = f.read(1024)

# Remove null padding characters (b\x00)

cleaned_data = raw_data.split(b'\x00')[0].decode('latin1', errors='ignore').strip()

if not cleaned_data or "XINUX" in cleaned_data or "GNU GRUB" in cleaned_data:

    # If the print command is not found, search deeper in the following sectors

    f.seek(1024)

    raw_data = f.read(512)

    cleaned_data = raw_data.split(b'\x00')[0].decode('latin1', errors='ignore').strip()

if not cleaned_data or "print" not in cleaned_data:

    print("Error: There are no files in the directory.")

    return

# Parse commands in the format: print filename.ext content_text

parts = cleaned_data.split(" ", 2)

if len(parts) >= 2 and parts[0] == "print":

    full_filename = parts[1]

    file_content = parts[2] if len(parts) > 2 else ""

    # Separate the filename and extension

    filename_only, file_ext = os.path.splitext(full_filename)

    print("\\n================ XINUX FILE SYSTEM EXPORT ================")

    print(f" [+] Full original name : {full_filename}")

    print(f" [+] Filename (Name)    : {filename_only}")

    print(f" [+] Extension           : {file_ext if file_ext else '(No extension)'}")

    print(f" [+] File content        : {file_content}")

    print("==========================================================")

else:

    print("Error: There are no files in the directory.")
```

if **name** == "**main**":

```
scan_xinux_data()
```

"""
with open("tools/ext2_scanner.py", "w") as f:

```
f.write(content)
```

print("[+] tools/ext2_scanner.py has been updated and improved!")
'

```
```
