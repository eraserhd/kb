package main

import (
	"machine"
	"time"
)

const (
	Power_Up_Reset = 0x3A
)

type Trackball struct {
	spiBus      machine.SPI
	slaveSelect machine.Pin
}

func (tb *Trackball) writeRegister(reg, value byte) error {
	tb.slaveSelect.Low()
	_, err := tb.spiBus.Transfer(0x80 | Power_Up_Reset)
	if err != nil {
		return err
	}
	_, err = tb.spiBus.Transfer(0x5a)
	if err != nil {
		return err
	}
	time.Sleep(20 * time.Microsecond)
	tb.slaveSelect.High()
	time.Sleep(100 * time.Microsecond)
	return nil
}

func main() {
	spi := machine.SPI0
	spi.Configure(machine.SPIConfig{
		Frequency: 125000,
		SCK:       machine.P0_17, // SS
		SDO:       machine.P0_06, // MI
		SDI:       machine.P0_08, // MO
		LSBFirst:  false,
		Mode:      3,
	})

	ssPin := machine.P0_20
	ssPin.Configure(machine.PinConfig{Mode: machine.PinOutput})

	tb := &Trackball{
		spiBus:      spi,
		slaveSelect: ssPin,
	}

	led := machine.LED
	led.Configure(machine.PinConfig{Mode: machine.PinOutput})

	led.Low()
	if err := tb.writeRegister(Power_Up_Reset, 0x5a); err != nil {
		led.High()
	}

	// VI MI MO SC SS MT GD RS - back side

	// ??
	// MI - P0.06
	// MO - P0.08
	// ??
	// ??
	// SC - P0.17
	// SS - P0.20

	time.Sleep(time.Minute)
}
