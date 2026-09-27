#include <efi.h>
#include <efilib.h>

EFI_STATUS
EFIAPI
efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    InitializeLib(ImageHandle, SystemTable);
    uefi_call_wrapper(SystemTable->ConOut->ClearScreen, 1, SystemTable->ConOut);

    Print(L"==================================================\n");
    Print(L"       XINUX OS - UEFI BOOTLOADER v1.0            \n");
    Print(L"       Architecture: x86_64 UEFI (64-bit)         \n");
    Print(L"==================================================\n\n");
    Print(L"[+] Khoi dong thanh cong tren nen tang UEFI thuc thu!\n");
    Print(L"[+] XINUX Kernel & Filesystem da san sang.\n\n");
    Print(L"Nhan phim bat ky de tiep tuc...");

    EFI_INPUT_KEY Key;
    while (uefi_call_wrapper(SystemTable->ConIn->ReadKeyStroke, 2, SystemTable->ConIn, &Key) != EFI_SUCCESS) {}

    return EFI_SUCCESS;
}
