/*
 * 'call print'
 *
 * INPUT:
 * %si = Null terminated string
 */
1:
    mov $0x0e, %ah
    int $0x10
print:
    lodsb
    cmp $0, %al
    jne 1b
    ret
