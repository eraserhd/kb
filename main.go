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
	spiBus      machine.SPI
	slaveSelect machine.Pin
}

func (tb *Trackball) writeRegister(reg, value byte) error {
	tb.slaveSelect.Low()
	_, err := tb.spiBus.Transfer(reg | 0x80)
	if err != nil {
		return err
	}
	_, err = tb.spiBus.Transfer(value)
	if err != nil {
		return err
	}
	time.Sleep(20 * time.Microsecond)
	tb.slaveSelect.High()
	time.Sleep(100 * time.Microsecond)
	return nil
}

func (tb *Trackball) readRegister(reg byte) (byte, error) {
	tb.slaveSelect.Low()
	_, err := tb.spiBus.Transfer(reg & 0x7f)
	if err != nil {
		return 0, err
	}
	result, err := tb.spiBus.Transfer(0)
	if err != nil {
		return 0, err
	}
	time.Sleep(20 * time.Microsecond)
	tb.slaveSelect.High()
	time.Sleep(100 * time.Microsecond)
	return result, nil
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

	led := machine.LED
	led.Configure(machine.PinConfig{Mode: machine.PinOutput})
	led.Low()

	tb := &Trackball{
		spiBus:      spi,
		slaveSelect: ssPin,
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
