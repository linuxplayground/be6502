        .include "acia.inc"
        .include "lcd.inc"
        .include "utils.inc"
        .include "tty.inc"
        .include "wozmon.inc"

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