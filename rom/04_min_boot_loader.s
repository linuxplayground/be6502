    .include "lcd.inc"
    .include "acia.inc"
    .include "xmodem.inc"
    .include "wozmon.inc"
    .include "zeropage.inc"
    .include "syscalls.inc"

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

    jsr go_help
    
prompt:
    jsr new_line
    lda #'>'
    jsr _acia_write_byte
    rts

; just echo stuff.
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
    jsr _acia_write_byte
    jsr prompt
    jmp loop

go_mon:
    jsr _wozmon
    jsr prompt
    jmp loop
    
go_xmodem:
    jsr _acia_write_byte
    jsr _xmodem
    jsr prompt
    jmp loop

go_run:
    jsr $1000
    jsr new_line
    jsr prompt
    jmp loop

go_help:
    lda #<load_message
    sta str_ptr
    lda #>load_message
    sta str_ptr + 1
    jsr _acia_write_string
    jsr prompt
    jmp loop

new_line:
    lda #$0d
    jsr _acia_write_byte
    rts

lcd_message:  .asciiz "Connect to tty                          On 8N1 19200"
load_message: .byte "Press 'x' to start xmodem receive ...", $0d
              .byte "Press 'r' to run your program ...", $0d
              .byte "Press 'm' to start Wozmon ...", $0d, $00


    .segment "VECTORS"

    .word $0000
    .word main
    .word $0000