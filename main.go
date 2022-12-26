package main

import (
	"fmt"
	"machine"
	"time"
)

const (
	Power_Up_Reset = 0x3A
	Motion         = 0x02
	Delta_X_L      = 0x03
	Delta_X_H      = 0x04
	Delta_Y_L      = 0x05
	Delta_Y_H      = 0x06
)

type Trackball struct {
	spi machine.SPI
	cs  machine.Pin
}

func (tb *Trackball) writeRegister(reg, value byte) error {
	tb.cs.Low()
	_, err := tb.spi.Transfer(reg | 0x80)
	if err != nil {
		return err
	}
	_, err = tb.spi.Transfer(value)
	if err != nil {
		return err
	}
	time.Sleep(20 * time.Microsecond)
	tb.cs.High()
	time.Sleep(100 * time.Microsecond)
	return nil
}

func (tb *Trackball) readRegister(reg byte) (byte, error) {
	tb.cs.Low()
	_, err := tb.spi.Transfer(reg & 0x7f)
	if err != nil {
		return 0, err
	}
	result, err := tb.spi.Transfer(0)
	if err != nil {
		return 0, err
	}
	time.Sleep(20 * time.Microsecond)
	tb.cs.High()
	time.Sleep(100 * time.Microsecond)
	return result, nil
}

func main() {
	spi := machine.SPI0
	spi.Configure(machine.SPIConfig{
		Frequency: 125000,
		SCK:       machine.P0_17, // SC
		SDO:       machine.P0_08, // MO
		SDI:       machine.P0_06, // MI
		LSBFirst:  false,
		Mode:      3,
	})

	cs := machine.P0_20
	cs.Configure(machine.PinConfig{Mode: machine.PinOutput})

	led := machine.LED
	led.Configure(machine.PinConfig{Mode: machine.PinOutput})
	led.Low()

	tb := &Trackball{
		spi: spi,
		cs:  cs,
	}
	if err := tb.writeRegister(Power_Up_Reset, 0x5a); err != nil {
		led.High()
	}

	// Wait for reboot
	time.Sleep(50 * time.Millisecond)

	if _, err := tb.readRegister(Motion); err != nil {
		led.High()
	}
	if _, err := tb.readRegister(Delta_X_L); err != nil {
		led.High()
	}
	if _, err := tb.readRegister(Delta_X_H); err != nil {
		led.High()
	}
	if _, err := tb.readRegister(Delta_Y_L); err != nil {
		led.High()
	}
	if _, err := tb.readRegister(Delta_Y_H); err != nil {
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

	for {
		time.Sleep(5 * time.Second)

		m, err := tb.readRegister(Motion)
		if err != nil {
			led.High()
		}
		dxl, err := tb.readRegister(Delta_X_L)
		if err != nil {
			led.High()
		}
		dxh, err := tb.readRegister(Delta_X_H)
		if err != nil {
			led.High()
		}
		dyl, err := tb.readRegister(Delta_Y_L)
		if err != nil {
			led.High()
		}
		dyh, err := tb.readRegister(Delta_Y_H)
		if err != nil {
			led.High()
		}

		fmt.Printf("m = %d, dxl = %d, dxh = %d, dyl = %d, dyh = %d\r\n", m, dxl, dxh, dyl, dyh)
	}
}
