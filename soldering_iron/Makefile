
MICROCONTROLLER = m328p
PROGRAMMER      = fiddyplus

CC              = avr-gcc

flash: firmware.hex
	avrdude -C +avrdude.conf -p $(MICROCONTROLLER) -c $(PROGRAMMER) -U flash:w:firmware.hex:i
.PHONY: flash

tty:
	avrdude -C +avrdude.conf -p $(MICROCONTROLLER) -c $(PROGRAMMER) -t
.PHONY: tty

firmware.elf: firmware.c
	avr-gcc -mmcu=atmega328p -Os -o firmware.elf firmware.c

firmware.hex: firmware.elf
	avr-objcopy -O ihex firmware.elf firmware.hex
