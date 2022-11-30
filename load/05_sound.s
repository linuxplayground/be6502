        .include "utils.inc"
        .include "via_const.inc"

        .import __VIA_START__
VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA

RESET = %00000100
LATCH = %00000111
WRITE = %00000110


        .code
        
        lda #$ff                        ; porta used to send data to the ay-3-8910
        sta VIA_DDRA
        lda #(RESET|LATCH|WRITE)        ; portb used to set selct registers and reset the ay-3-8910
        sta VIA_DDRB

init:
        jsr reset

        ; set up channel A at full volume
        lda #$3e
        ldx #$07
        jsr write_register
        lda #$0f
        ldx #$08
        jsr write_register

        ; do descending notes
        ldy #$00
descending:
        tya
        ldx #$00
        jsr write_register
        lda #$00
        ldx #$01
        jsr write_register
        lda #8
        jsr _delay_ms
        iny
        bne descending
exit:
        jsr reset
        rts

reset:
        lda #$00
        sta VIA_PORTB
        lda #10
        jsr _delay_ms
        lda #RESET
        sta VIA_PORTB
; a contains value to send
; x contains register to send to.
write_register:
        pha                             ; preserve registers

        lda #(LATCH)
        sta VIA_PORTB
        txa
        sta VIA_PORTA                   ; write register

        lda #(RESET)
        sta VIA_PORTB

        lda #(WRITE)
        sta VIA_PORTB
        pla
        sta VIA_PORTA                   ; write data

        lda #(RESET)
        sta VIA_PORTB
        rts