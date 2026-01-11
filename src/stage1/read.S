.code16

/*
 * 'call read'
 *
 * Read with DAP (AH = 0x42, INT = 0x13).
 * Errors if failed.
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
/* NOTE: Maybe a CHS as a fallback in the future? */
    nop
read.failed:
    stc
read.return:
    ret
