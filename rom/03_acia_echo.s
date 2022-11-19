    .include "lcd.inc"
    .include "acia.inc"
    .include "zeropage.inc"

    .code 
main:
    ldx #$ff
    txs

    jsr _lcd_init
    jsr _acia_init

    lda #<lcd_message
    sta str_ptr
    lda #>lcd_message
    sta str_ptr + 1
    jsr _lcd_print

    lda #<acia_message
    sta str_ptr
    lda #>acia_message
    sta str_ptr + 1
    jsr _acia_write_string
    jsr new_line

; just echo stuff.
loop:
    jsr _acia_read_byte
    jsr _acia_write_byte
    jmp loop

new_line:
    lda #$0d
    jsr _acia_write_byte
    rts

lcd_message:  .asciiz "Connect to tty                          On 8N1 19200 bps"
acia_message: .asciiz "Hello, Serial!"

    .segment "VECTORS"

    .word $0000
    .word main
    .word $0000