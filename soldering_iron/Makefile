
MICROCONTROLLER = m328p
PROGRAMMER      = fiddyplus

tty:
	avrdude -C +avrdude.conf -p $(MICROCONTROLLER) -c $(PROGRAMMER) -t
.PHONY: tty
