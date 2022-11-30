        .include "acia.inc"
        .include "zeropage.inc"
        
init:
        lda #<greeting
        sta str_ptr
        lda #>greeting
        sta str_ptr + 1
        jsr _acia_write_string
        rts

        .RODATA
greeting: .asciiz "Hello, First loadable."