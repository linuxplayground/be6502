        .include "lcd.inc"
        .include "zeropage.inc"

    .code 
main:
    ldx #$ff
    txs

    jsr _lcd_init

    lda #<message
    sta str_ptr
    lda #>message
    sta str_ptr+1
    jsr _lcd_print
end:
    jmp end

message:  .asciiz "Hello, World!"

    .segment "VECTORS"

    .word $0000
    .word main
    .word $0000