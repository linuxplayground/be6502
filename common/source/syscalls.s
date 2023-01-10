        .include "acia.inc"
        .include "lcd.inc"
        .include "utils.inc"
        .include "tty.inc"
        .include "wozmon.inc"
        .include "vdp.inc"

        ; acia
        .export _syscall__acia_read_byte
        .export _syscall__acia_read_byte_nw
        .export _syscall__acia_is_data_available
        .export _syscall__acia_write_byte
        .export _syscall__acia_write_string
        ; lcd
        .export _syscall__lcd_write_byte
        .export _syscall__lcd_read_byte
        .export _syscall__lcd_print
        ; tty
        .export _syscall__new_line
        .export _syscall__prompt
        ; utils
        .export _syscall__delay_ms
        .export _syscall__delay_sec
        ;wozmon
        .export _syscall__prbyte
        ;vdp
        .export _syscall__vdp_reset
        .export _syscall__vdp_clear_screen
        .export _syscall__vdp_print
        .export _syscall__vdp_set_ram_address
        .export _syscall__vdp_cout
        .export _syscall__vdp_set_register

        .segment "SYSCALLS"
; acia
_syscall__acia_read_byte:               .word _acia_read_byte
_syscall__acia_read_byte_nw:            .word _acia_read_byte_nw
_syscall__acia_is_data_available:       .word _acia_is_data_available
_syscall__acia_write_byte:              .word _acia_write_byte
_syscall__acia_write_string:            .word _acia_write_string
; lcd
_syscall__lcd_write_byte:               .word _lcd_write_byte
_syscall__lcd_read_byte:                .word _lcd_read_byte
_syscall__lcd_print:                    .word _lcd_print
; tty
_syscall__new_line:                     .word _new_line
_syscall__prompt:                       .word _prompt
; utils
_syscall__delay_ms:                     .word _delay_ms
_syscall__delay_sec:                    .word _delay_sec
; wozmon
_syscall__prbyte:                       .word _prbyte
; vdp
_syscall__vdp_reset:                    .word _vdp_reset
_syscall__vdp_clear_screen:             .word _vdp_clear_screen
_syscall__vdp_print:                    .word _vdp_print
_syscall__vdp_set_ram_address:          .word _vdp_set_ram_address
_syscall__vdp_cout:                     .word _vdp_cout
_syscall__vdp_set_register:             .word _vdp_set_register
