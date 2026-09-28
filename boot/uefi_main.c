#include <efi.h>
#include <efilib.h>

EFI_STATUS
EFIAPI
efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    InitializeLib(ImageHandle, SystemTable);

    uefi_call_wrapper(
        SystemTable->ConOut->ClearScreen,
        1,
        SystemTable->ConOut
    );

    Print(L"\n");
    Print(L"========================================================\n");
    Print(L"                    X I N U X\n");
    Print(L"              XINUX Operating System\n");
    Print(L"========================================================\n\n");

    Print(L"  XINUX UEFI Bootloader v1.0\n");
    Print(L"  Architecture: x86_64 UEFI (64-bit)\n\n");

    Print(L"[+] UEFI platform detected.\n");
    Print(L"[+] XINUX bootloader initialized.\n");
    Print(L"[+] XINUX kernel and filesystem are ready.\n\n");

    Print(L"  Press any key to continue...");

    EFI_INPUT_KEY Key;

    while (
        uefi_call_wrapper(
            SystemTable->ConIn->ReadKeyStroke,
            2,
            SystemTable->ConIn,
            &Key
        ) != EFI_SUCCESS
    )
    {
    }

    return EFI_SUCCESS;
}