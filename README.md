# BE6502 - Ben Eater Breadboard Computer

Differences to the Ben Eater videos:

- Includes a UART Rockwell 6551.
- Assembly code is compiled using CA65 and CL65 for linking.
- Much of the OS is based on Dawid Buschwald's OS/1  - https://github.com/dbuchwald/6502
- I have a PS2 keyboard that's interfaced with a PIC micro controller similar to https://github.com/visrealm/hbc-56
- I have an AY-3-8910 which I have been playing with.

## The ROM

There are various versions of the ROM, but the one I am using mostly is `05_minmon_basic` which includes ehbasic, wozmon and xmodem for loading programs.

## Load programs

The load programs must be compiled to start at 0x1000 and the loadtrim.py script is used to insert that address into the beginning of compiled files.
Some OS routines are available in your load programs - see Dawid Bushwald's detailed explanation of how this works for more information.

