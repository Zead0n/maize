ENTRY(_start)

SECTIONS
{
    . = 0xf000;

    .text :
    {
        *(.text.entry)
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
