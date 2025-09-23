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
        *(.data.*)
    }

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    }

    .bss :
    {
        *(.bss)
        *(.bss.*)
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
