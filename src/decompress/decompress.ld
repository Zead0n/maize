ENTRY(_start)

SECTIONS
{
    . = 0x70000;

    .text :
    {
        *(.entry)
        *(.text .text.*)
    }

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    }
    .data :
    {
        *(.data)
        *(.data.*)
    }
    .bss :
    {
        bss_begin = .;
        *(.bss .bss.*)
        *(COMMON)
        bss_end = .;
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note.GNU-stack)
    }
}
