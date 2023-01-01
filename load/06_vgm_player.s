; play vgm encoded files for ay-3-8910
; files must be uncompressed before including.
; files must fit in ram.
;
; Connections for use with a VIA
;
; VIA           AY-3-8910
; ----------- | ---------
; PORTA A0-A7 | D0-D7
; PORTB B5    | BC1
;             | BC2 5V
; PORTB B6    | BDIR
; PORTB B7    | /RESET
;             | A8 5V
;             | /A9 GND

        .include "acia.inc"

        .import __VIA_START__
        .import __RAM_START__
        .import __RAM_SIZE__
__RAM_END__ = __RAM_START__ + __RAM_SIZE__

        .zeropage
fpos:           .res 2          ; 16 bit pointer to place in file.
data:           .res 2          ; 16 bit data value

VIA_REGISTER_PORTB = $00
VIA_REGISTER_PORTA = $01
VIA_REGISTER_DDRB  = $02
VIA_REGISTER_DDRA  = $03

VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA

RESET = %10000000
LATCH = %11100000
WRITE = %11000000
READ  = %10100000


        .code
init:
        lda #<vgm_file          ; store location of first byte of vgm file
        sta fpos                ; into file into fpos zeropage pointer
        lda #>vgm_file
        sta fpos + 1

        ; set up VIA pin directions
        lda #$ff                ; porta used to send data to the ay-3-8910
        sta VIA_DDRA
        lda #(RESET|LATCH|WRITE); portb used to set registers and reset the ay-3-8910
        sta VIA_DDRB

        jsr reset               ; reset the AY-3-8910


; There is lots of information in the header.  This program
; only uses the header to determine the location of the start of data.
; The value in position 0x34 of the header contains an offset from this
; location to the start of data.
read_header:
        ldy #$34                ; VGM DATA OFFSET
        lda (fpos),y
        clc
        adc #$34                ; add offset to position 0x34 in header
                                ; A now contains first place in data.
        jsr addfpos             ; fpos is now at start of data.

; command parser and loop.  The VGM file is read sequentially with each command
; processed, then the following bytes loaded for data (or not depending on the command)
; until a command that's not recognised appears or the 0x66 END OF DATA command is read.

loop:                           ; go through each command, reading in the next bytes
                                ; and performing the steps required.
        lda (fpos)
        cmp #$61                ; pause
        beq @do_pause
        cmp #$a0                ; write register
        beq @do_play
        cmp #$62                ; 60th sec
        beq @do_pause_60
        cmp #$63                ; 50th sec
        beq @do_pause_50
        cmp #$66
        beq @do_good_exit
        and #$f0
        cmp #$70
        beq @do_short_pause     ; a 0x7x is a short pause of less than 15 chars.
@do_bad_exit:                   ; unrecognised command
        jsr prhex               ; print the ascii value of the command.
        lda #'!'
        jsr _acia_write_byte    ; print ! to indicate error.
        jmp exit
@do_good_exit:
        jmp exit
@do_pause:
        jsr incfpos
        lda (fpos)
        sta data
        jsr incfpos
        lda (fpos)
        sta data + 1
        jsr wait_samples
        jmp @next_command
@do_pause_50:
        lda #$03
        sta data + 1
        lda #$72
        sta data
        jsr wait_samples
        jmp @next_command
@do_pause_60:
        lda #$02
        sta data + 1
        lda #$df
        sta data
        jsr wait_samples
        jmp @next_command
@do_short_pause:
        lda (fpos)              ; we nuked A when we checked if the high nibble was $7
        and #$0f                ; mask out the low nibble
        sta data
        stz data + 1            ; this command is for short pauses.  high byte is zero
        jsr wait_samples
        jmp @next_command
@do_play:
        jsr incfpos
        lda (fpos)
        sta data
        jsr incfpos
        lda (fpos)
        sta data + 1
        jsr write_register
        ; fall through
@next_command:
        jsr incfpos
        ; lda (fpos)              ; DEBUG: printing debug statements slows the program down
        ; jsr prbyte              ; DEBUG: Prints next command hex.
        ; jsr newline             ; DEBUG: comment these out for production
        jmp loop

reset:
        lda #$00
        sta VIA_PORTB
        lda #$ff                ; use the wait samples routine here for a short
        sta data + 1            ; reset delay.  Perhaps you have some other
        stz data                ; delay routine you can use if you want.
        jsr wait_samples        ; to keep this demo simple, I am avoiding
        lda #RESET              ; referenceing anything in my bios.
        sta VIA_PORTB
        rts

; waits a number of samples.  each sample at 1mhz is about 22 cycles.
; samples are at 44100 hz on vgm files
                                ; (6)   6 cycles to jump here.
wait_samples:
        lda data                ; (3)                 
        bne @wait_samples_1     ; (2)   (could be 3 if branching across page)
        lda data + 1            ; (3)
        beq @return             ; (2)   (could be 3 if branching across page)
        dec data + 1            ; (5)     
@wait_samples_1:
        dec data                ; (5)
        ; kill some cycles between loops.  Adjust as required.
        nop                     ; (2)
        nop                     ; (2)
        nop                     ; (2)
        nop                     ; (2)
        nop                     ; (2)
        jmp wait_samples        ; (3)   loop = 29 cycles
@return:
        rts                     ; (6)   6 cycles to return


write_register:
        pha                     ; preserve registers

        lda #(LATCH)            ; latch mode
        sta VIA_PORTB
        lda data
        sta VIA_PORTA           ; write register number

        lda #(RESET)            ; inactive
        sta VIA_PORTB

        lda #(WRITE)            ; data / write mode
        sta VIA_PORTB
        lda data + 1
        sta VIA_PORTA           ; write data

        lda #(RESET)            ; inactive
        sta VIA_PORTB

        pla                     ; restore registers
        rts

; add 8 bit number to 16bit fpos
addfpos:
        clc
        adc fpos
        sta fpos
        bcc @return
        inc fpos+1
        ldx fpos+1
        cpx #>__RAM_END__       ; check that the hi byte of the position is not greater
        bcc @return             ; than end of ram hi byte.
        jmp exit                ; if it is, exit.
@return:
        rts

; increment fpos pointer
incfpos:
        inc fpos
        bne @return
        inc fpos+1
        lda fpos+1
        cmp #>__RAM_END__       ; check that the hi byte of the position is not greater
        bcc @return             ; than end of ram hi byte.
        jmp exit                ; if it is, exit.
@return:
        rts

; print ascii value of a byte. - Taken from wozmon
prbyte:
        pha                     ; Save A for LSD.
        lsr
        lsr
        lsr                     ; MSD to LSD position.
        lsr
        jsr prhex               ; Output hex digit.
        pla                     ; Restore A.
prhex:
        and #$0f                ; Mask LSD for hex print.
        ora #$b0                ; Add "0".
        cmp #$ba                ; Digit?
        bcc echo                ; Yes, output it.
        adc #$06                ; Add offset for letter.
echo:
        and #$7f                ; back to standard ascii
        jsr _acia_write_byte
        rts

; output a new line sequence to tty.
; clobbers A
newline:
        lda #$0a
        jsr _acia_write_byte
        lda #$0d
        jsr _acia_write_byte
        rts

; exit gracefully and return to calling application (monitor)
exit:
        lda #'/'                ; print / to indicate OK exit.
        jsr _acia_write_byte    
        lda #0                  ; reset the ay-3-8910 to turn off any
        sta VIA_PORTB           ; residual noise
        rts


vgm_file:
        ; .incbin "../audio/01_moonpatrol"
        ; .incbin "../audio/01_bombjack_trimmed"
        ; .incbin "../audio/01_bubble"
        .incbin "../audio/02_bubble_main"
