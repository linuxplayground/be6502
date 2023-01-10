        .include "utils.inc"
        .include "vdp.inc"
        .include "zeropage.inc"

        .code

main:
        jsr _vdp_reset  ; default is text mode black on grey and clear screen

        ldx #7
        lda #$F1                ; set colors.
        jsr _vdp_set_register

        ldx #0
        ldy #12
        jsr _vdp_set_ram_address

        lda #<signon
        sta str_ptr
        lda #>signon
        sta str_ptr + 1
        jsr _vdp_print
        rts

signon: .asciiz "WELCOME TO TMS9918A - NTSC GRAPHICS FROM 1974"
