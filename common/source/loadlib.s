        .include "syscalls.inc"

        ; acia
        .export _acia_read_byte
        .export _acia_read_byte_nw
        .export _acia_is_data_available
        .export _acia_write_byte
        .export _acia_write_string
        ; lcd
        .export _lcd_write_byte
        .export _lcd_read_byte
        .export _lcd_print
        ; tty
        .export _new_line
        .export _prompt
        ; utils
        .export _delay_ms
        .export _delay_sec
        ; wozmon
        .export _prbyte
        ; vdp
        .export _vdp_reset
        .export _vdp_clear_screen
        .export _vdp_print
        .export _vdp_set_ram_address
        .export _vdp_cout
        .export _vdp_set_register

        .code

; acia
_acia_read_byte:                jmp (_syscall__acia_read_byte)
_acia_read_byte_nw:             jmp (_syscall__acia_read_byte_nw)
_acia_is_data_available:        jmp (_syscall__acia_is_data_available)
_acia_write_byte:               jmp (_syscall__acia_write_byte)
_acia_write_string:             jmp (_syscall__acia_write_string)
; lcd
_lcd_write_byte:                jmp (_syscall__lcd_write_byte)
_lcd_read_byte:                 jmp (_syscall__lcd_read_byte)
_lcd_print:                     jmp (_syscall__lcd_print)
; tty
_new_line:                      jmp (_syscall__new_line)
_prompt:                        jmp (_syscall__prompt)
; utils
_delay_ms:                      jmp (_syscall__delay_ms)
_delay_sec:                     jmp (_syscall__delay_sec)
;wozmon
_prbyte:                        jmp (_syscall__prbyte)
;vdp
_vdp_reset:                     jmp (_syscall__vdp_reset)
_vdp_clear_screen:              jmp (_syscall__vdp_clear_screen)
_vdp_print:                     jmp (_syscall__vdp_print)
_vdp_set_ram_address:           jmp (_syscall__vdp_set_ram_address)
_vdp_cout:                      jmp (_syscall__vdp_cout)
_vdp_set_register:              jmp (_syscall__vdp_set_register)
