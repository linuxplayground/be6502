      .include "via_const.inc"

      .import __VIA_START__
      .import __ACIA_START__

    .export VIA_PORTB
    .export VIA_PORTA
    .export VIA_DDRB
    .export VIA_DDRA


VIA_PORTB = __VIA_START__ + VIA_REGISTER_PORTB
VIA_PORTA = __VIA_START__ + VIA_REGISTER_PORTA
VIA_DDRB  = __VIA_START__ + VIA_REGISTER_DDRB
VIA_DDRA  = __VIA_START__ + VIA_REGISTER_DDRA
