; draw a box in assembly to see how much faster it is.
        .include "acia.inc"
        .include "wozmon.inc"
        .include "zeropage.inc"

        .code
main:
        jsr cls
c1:
        lda #'|'
        ldx #1
        ldy #25
        jsr p_col
c2:
        lda #'|'
        ldx #79
        ldy #25
        jsr p_col
r1:
        lda #'-'
        ldx #80
        ldy #1
        jsr p_row
r2:
        lda #'-'
        ldx #80
        ldy #24
        jsr p_row

display_message:
        ldx #34
        ldy #12
        lda #'H'
        jsr plotxy
        lda #<message
        sta str_ptr
        lda #>message
        sta str_ptr + 1
        jsr _acia_write_string

        ldx #1
        ldy #26
        lda #'.'
        jsr plotxy
        jmp exit

p_row:
        dex
        beq @end_p_row
        jsr plotxy
        jmp p_row
@end_p_row:
        rts


p_col:
        dey
        beq @end_p_col
        jsr plotxy
        jmp p_col
@end_p_col:
        rts


exit:
        rts

; ansi plot A at location X=column, Y=line
; preserves A
plotxy:
        phx
        phy

        pha
        phx
        phy

        lda #$1b
        jsr _acia_write_byte
        lda #'['
        jsr _acia_write_byte
        ply
        tya
        jsr pr8dec
        lda #';'
        jsr _acia_write_byte
        plx
        txa
        jsr pr8dec
        lda #'H'
        jsr _acia_write_byte
        pla
        jsr _acia_write_byte

        ply
        plx
        rts

pr8dec:
        ldx #$ff
        sec
@prdec100:
        inx
        sbc #100
        bcs @prdec100
        adc #100
        jsr @prdig
        ldx #$ff
        sec
@prdec10:
        inx
        sbc #10
        bcs @prdec10
        adc #10
        jsr @prdig
        tax
@prdig:
        pha
        txa
        ora #'0'
        jsr _acia_write_byte
        pla
        rts
; ansi escape to clear screen
cls:
        lda #<ansi_cls
        sta str_ptr
        lda #>ansi_cls
        sta str_ptr + 1
        jsr _acia_write_string
        rts
        
        .RODATA
ansi_cls:
        .byte $1b,"[2J"
message:
        .asciiz "ELLO, WORLD!"
