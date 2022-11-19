    .include "io.inc"
    .include "utils.inc"

    .code 
main:
    ldx #$ff
    txs

    lda #$ff
    sta VIA_DDRB

@loop:
    lda #$aa
    sta VIA_PORTB
    lda #1
    jsr _delay_sec
    lda #$55
    sta VIA_PORTB
    lda #1
    jsr _delay_sec
    jmp @loop

    .segment "VECTORS"

    .word $0000
    .word main
    .word $0000