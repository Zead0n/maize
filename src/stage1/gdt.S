.align 8
gdtr:
    .word gdt_end - gdt_base - 1
    .long gdt_base
gdt_base:

gdt_null:
    .long 0
    .long 0
gdt_code:
    .word 0xffff        /* Limit (16 bits) */
    .word 0             /* Base (16 bits) */
    .byte 0             /* Base+ (8 bits) */
    .byte 0b10011010    /* Present (1 bit), Privilage (2 bits), Type (1 bit) */
                        /* Executable (1 bit), Conform (1 bit), Read (1 bit), Access (1 bit) */
    .byte 0b11001111    /* Granular (1 bit), Size (1 bit), Long (1 bit), Reserved (1 bit) */
                        /* Limit+ (4 bits)*/
    .byte 0             /* Base++ (8 bits)*/
gdt_data:
    .word 0xffff        /* Limit (16 bits) */
    .word 0             /* Base (16 bits) */
    .byte 0             /* Base+ (8 bits) */
    .byte 0b10010010    /* Present (1 bit), Privilage (2 bits), Type (1 bit) */
                        /* Executable (1 bit), Direction (1 bit), Write (1 bit), Access (1 bit) */
    .byte 0b11001111    /* Granular (1 bit), Size (1 bit), Long (1 bit), Reserved (1 bit) */
                        /* Limit+ (4 bits)*/
    .byte 0             /* Base++ (8 bits)*/

gdt_end:
