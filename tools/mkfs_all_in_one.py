import os

def build_all_in_one():

    output_img = "xinux_all_in_one.img"

    mbr_path = "boot/mbr.bin"

    setup_path = "boot/setup.bin"

    if not os.path.exists(mbr_path) or not os.path.exists(setup_path):

        print("[-] Error: mbr.bin or setup.bin has not been compiled yet! Run make first.")

        return

    # Create a 12 MB disk image (enough space for both the OS and Data)

    total_size = 12 * 1024 * 1024

    print("[*] Initializing All-in-One image (12 MB)...")

    with open(output_img, "wb") as f:

        # Fill the entire image with 0x00

        f.write(b"\x00" * total_size)

    # Load the MBR into sector 0 (offset 0)

    with open(output_img, "r+b") as f:

        with open(mbr_path, "rb") as mbr:

            f.seek(0)

            f.write(mbr.read())

        # Load Setup into sector 1 (offset 512 bytes)

        with open(setup_path, "rb") as setup:

            f.seek(512)

            f.write(setup.read())

    print(f"[+] Successfully packaged into file: {output_img}")

    print(f"[+] You can now use Rufus to write {output_img} to a USB drive and boot it on a real machine!")

if __name__ == "__main__":

    build_all_in_one()