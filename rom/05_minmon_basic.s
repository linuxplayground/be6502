    ; .include "lcd.inc"
    .include "acia.inc"
    .include "io.inc"
    .include "via_const.inc"
    .include "xmodem.inc"
    .include "wozmon.inc"
    .include "zeropage.inc"
    .include "syscalls.inc"
    .include "ehbasic.inc"
    .include "tty.inc"

    .export _monmain
    .export _monloop

    .code 
_monmain:
main:
    sei
    ldx #$ff
    txs

    ; jsr _lcd_init
    jsr _acia_init

    ; lda #<lcd_message
    ; sta str_ptr
    ; lda #>lcd_message
    ; sta str_ptr + 1
    ; jsr _lcd_print

    cli
    jsr go_help


; just echo stuff.
_monloop:
loop:
    jsr _acia_read_byte
    cmp #'x'
    beq go_xmodem
    cmp #'r'
    beq go_run
    cmp #'m'
    beq go_mon
    cmp #'h'
    beq go_help
    cmp #'b'
    beq go_basic
    jsr _prompt
    jmp loop

go_mon:
    jsr _wozmon
    jsr _prompt
    jmp loop
    
go_xmodem:
    jsr _xmodem
    jmp loop

go_run:
    jsr $1000
    jsr _new_line
    jmp loop

go_help:
    lda #<load_message
    sta str_ptr
    lda #>load_message
    sta str_ptr + 1
    jsr _acia_write_string
    jmp loop

go_basic:
    jsr BASIC_init
    jmp loop


; lcd_message:  .asciiz "Connect to tty                          On 8N1 19200"
load_message: .byte "Press 'x' to start xmodem receive ...", $0a, $0d
              .byte "Press 'r' to run your program ...", $0a, $0d
              .byte "Press 'b' to run basic ...", $0a, $0d
              .byte "Press 'm' to start Wozmon ...", $0a, $0d, $00


; user defined IRQ vector
irq:
    jmp (usr_irq)         ; user programs can define an IRQ jmp here.

    .segment "VECTORS"

    .word $0000
    .word main
    .word irq
