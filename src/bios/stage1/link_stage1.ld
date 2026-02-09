ENTRY(_start)

SECTIONS
{
    . = 0x7c00;

    .text :
    {
        *(.text.boot)
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

    . = 0x7dbe;
    .partition_table :
    {
        /* partition table entry 0 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 1 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 2 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 3 */
        QUAD(0)
        QUAD(0)
    }

    . = 0x7dfe;
    .magic :
    {
        SHORT(0xaa55)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame*)
        *(.note .note.*)
    }
}
