OUTPUT_FORMAT(binary)
ENTRY(_start)

SECTIONS
{
    . = 0x7c00;

    .text :
    {
        *(.text.boot)
        *(.text)
    }

    .data :
    {
        *(.data)
    }

    .rodata :
    {
        *(.rodata)
    }

    .bss :
    {
        *(.bss)
    }
}
