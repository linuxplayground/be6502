        .include "zeropage.inc"
        
        .import __ACIA_START__
        .export ACIA_DATA
        .export ACIA_STATUS
        .export ACIA_COMMAND
        .export ACIA_CONTROL
        .export _acia_init
        .export _acia_is_data_available
        .export _acia_read_byte
        .export _acia_read_byte_nw
        .export _acia_write_byte
        .export _acia_write_string

ACIA_DATA    = __ACIA_START__ + $00
ACIA_STATUS  = __ACIA_START__ + $01
ACIA_COMMAND = __ACIA_START__ + $02
ACIA_CONTROL = __ACIA_START__ + $03

_acia_init:
        lda #$00
        sta ACIA_STATUS
        lda #$0b
        sta ACIA_COMMAND
        lda #$1f
        sta ACIA_CONTROL
        rts

; if carry is set, then there is data availble - unset if no data
_acia_is_data_available:
        clc
        lda ACIA_STATUS
        and #$08
        bne @return
        sec
@return:
        rts

; get data without blocking
_acia_read_byte_nw:
        clc
        lda    ACIA_STATUS
        and    #$08 
        beq    @done
        lda    ACIA_DATA
        sec
@done:
        rts

; blocks
_acia_read_byte:
@wait_rxd_full:
        lda ACIA_STATUS
        and #$08
        beq @wait_rxd_full
        lda ACIA_DATA
        rts

_acia_write_byte:
        pha                     ; save char
@wait_txd_empty:
        lda ACIA_STATUS
        and #$10
        beq @wait_txd_empty
        pla                     ; restore char
        sta ACIA_DATA
        rts

; writes what ever is in str_ptr to terminal
_acia_write_string:
        ldy #$00
@loop:
        lda (str_ptr),y
        beq @done
        jsr _acia_write_byte
        iny
        jmp @loop
@done:
        rts
