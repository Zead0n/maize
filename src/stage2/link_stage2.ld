ENTRY(_start)

SECTIONS
{
    . = 0xC000;

    .text :
    {
        *(.text)
        *(.text.*)
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

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note.GNU-stack)
    }
}
