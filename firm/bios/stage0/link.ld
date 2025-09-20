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

    . = 0x7c00 + 510;

    .magic :
    {
        SHORT(0xaa55)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note.GNU-stack)
    }
}
