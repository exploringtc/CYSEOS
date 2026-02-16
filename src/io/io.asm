section .text

global insb
global insw
global outb
global outw

; unsigned char insb(unsigned short port)
; Read a byte from the I/O port
insb:
    mov dx, [esp + 4]    ; port is in EDX (second argument)
    in al, dx            ; Read byte from port into AL
    ret

; unsigned short insw(unsigned short port)
; Read a word from the I/O port
insw:
    mov dx, [esp + 4]    ; port is in EDX (second argument)
    in ax, dx            ; Read word from port into AX
    ret

; void outb(unsigned short port, unsigned char val)
; Write a byte to the I/O port
outb:
    mov dx, [esp + 4]    ; port is in EDX (first argument after return address)
    mov al, [esp + 8]    ; value is in AL (second argument)
    out dx, al           ; Write byte to port
    ret

; void outw(unsigned short port, unsigned short val)
; Write a word to the I/O port
outw:
    mov dx, [esp + 4]    ; port is in EDX (first argument after return address)
    mov ax, [esp + 8]    ; value is in AX (second argument)
    out dx, ax           ; Write word to port
    ret
