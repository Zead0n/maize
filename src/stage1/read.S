.code16

/*
 * 'call read'
 *
 * Read with DAP (AH = 0x42, INT = 0x13).
 * Fallback to CHS (AH = 0x02, INT = 0x13).
 * Errors if both failed.
 *
 * INPUT:
 * %ds:%si = Data packet address
 * %dl = Drive number
 *
 * RETURN:
 * `Carry` set if error
 */
read:
    push %dx

    /* Check if hard drive */
    cmpb $0x80, %dl
    jb read.fallback

    /* Check for LBA support */
    movw $0x55aa, %bx
    movb $0x41, %ah
    int $0x13

    jc read.fallback
    cmpw $0xaa55, %bx
    jne read.fallback
    testb $0x01, %cl
    jz read.fallback

    pop %dx

    movb $0x42, %ah
    int $0x13
    jc read.failed
    jmp read.return
read.fallback:
    mov $0x08, %ah
    int $0x13
    jc read.failed

    /* Store head */
    movzbw %dh, %ax
    incw %ax
    movw %ax, max_head

    /* Store cylinders */
    movzbw %cl, %dx
    shlw $2, %dx
    mov %dh, %ah
    mov %ch, %al
    incw %ax
    movw %ax, max_cylinder

    /* Store sectors */
    movzbw %dl, %ax
    shrw $2, %ax
    movw %ax, max_sector

    /* Get LBA */
    movw %ds:8(%si), %ax
    test %ax, %ax
    jnz read.failed
    movw %ds:10(%si), %ax
    test %ax, %ax
    jnz read.failed
    movw %ds:12(%si), %ax
    test %ax, %ax
    jnz read.failed

    movw %ds:14(%si), %ax

    /* Calculate sector */
    xorw %dx, %dx
    divw max_sector
    movb %dl, %cl
    incb %cl                 /* Sectors are 1-based */

    xorw %dx, %dx
    divw max_head

    /* Calculate cylinder */
    cmpw max_cylinder, %ax
    jg read.failed

    movb %al, %ch
    xorb %al, %al
    shrw $2, %ax
    orb %al, %cl

    /* Set head (%dl already contains the head) */
    movb %dl, %al

    pop %dx

    mov %al, %dh

    /* Set segment:offset */
    mov %ds:6(%si), %es
    mov %ds:4(%si), %bx

    movb %ds:3(%si), %al
    movb $2, %ah

    int $0x13
    jc read.failed

    jmp read.return
read.failed:
    stc
read.return:
    ret

max_head:
    .word 0x0000
max_cylinder:
    .word 0x0000
max_sector:
    .word 0x0000
