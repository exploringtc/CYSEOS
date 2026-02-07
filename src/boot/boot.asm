ORG 0x7c00
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Short jumps explained later
_start:
    jmp short start
    nop
; CS becomes 0 making equation
; 0x00 * 16 + offset. Our origin is
; 0x8c00 this is correct.
start:
    jmp 0:step2

step2:
    cli ; Clear interrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti ; Enable interrupts

.load_protected:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; GDT
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:       ; CS SHOULD POINT TO THIS
    dw 0xffff   ; Segment limit first 0-15 bits
    dw 0        ; Base first 0-15 bits
    db 0        ; Base 16-23 bits
    db 0x9a     ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

; offset 0x10
gdt_data:
    dw 0xffff       ; DS, SS, ES, FS, GS
    dw 0            ; Segment limit first 0-15 bits
    db 0            ; Base first 0-15 bits
    db 0x92         ; Access byte
    db 11001111b    ; High 4 bit flags and the low 4 bit flags
    db 0            ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1 ; Limit
    dd gdt_start ; Base

[BITS 32]
load32: 
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp

; Enable the A20 line
    in al, 0x92
    or al, 2
    out 0x92, al
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; LOAD THE KERNEL
    ; The LBA sector number 0 is out
    ; bootloader is the second sector
    mov eax, 1
    ; Total sectors to read
    ;bytes = 512 * 100 = 51,00 bytes loaded
    mov ecx, 100
    ; The address in memory to load the sectors into
    mov edi, 0x0100000
    call ata_lba_read
    ;Now its loaded jump to where we loaded the kernel
    ; which will execute our kernel.asm file
    ; CODE_SEG ensures the CS register becomes 
    ; the code selector specified in GDT
    ; enforcing the GDT code rules for execution
    jmp CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax ; backup the LBA
    ; Send the highest 8 bits of the lba to hard disk controller
    shr eax, 24
    or eax, 0xE0 ; select the master drive
    mov dx, 0x1F6
    out dx, al
    ; Finishe sending the highest 8 bits of the lba

    ; send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; finished sending the total sectors to read

    ; send more bits of the LBA
    mov eax, ebx ; restore the backup LBA
    mov dx, 0x1F3
    out dx, al
    ; finished sending more bits of the LBA

    ; send more bits of the LBA
    mov dx, 0x1F4
    mov eax, ebx ; restore the backup LBA
    shr eax, 8
    out dx, al
    ; finished sending more bits of the LBA

    ; send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx ; restore the backup LBA
    shr eax, 16
    out dx, al
    ; finished sending upper 16 bits of the LBA

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

    ; read all sectors into memory
.next_sector:
    push ecx

; checking if we need to read
.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again

; we need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ; end of reading sectors into memory
    ret

times 510-($-$$) db 0
dw 0xAA55
