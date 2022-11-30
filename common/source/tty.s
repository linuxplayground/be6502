        .include "acia.inc"
        .include "zeropage.inc"

        .export _new_line
        .export _prompt

        .code

_new_line:
        lda #<nl
        sta str_ptr
        lda #>nl
        sta str_ptr + 1
        jsr _acia_write_string
        rts

_prompt:
    jsr _new_line
    lda #'>'
    jsr _acia_write_byte
    rts

        .RODATA
nl:           .byte $0a, $0d, $00
