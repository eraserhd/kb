#define F_CPU 1000000UL

#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define DEBOUNCE_MS  50
#define TEMPERATURE_EEPROM_ADDRESS ((uint16_t*)0)

enum
{
    MODE_RUN     = 0,
    MODE_SET_100,
    MODE_SET_10,
    MODE_SET_1,
    MODE_STORE_THEN_RUN,
};

typedef struct mode_state_tag
{
    uint8_t mode;
    uint16_t current_temperature;
    uint16_t set_temperature;
    uint16_t next_temperature;
}
mode_state_t;

volatile mode_state_t mode_state =
{
    .mode = MODE_RUN,
    .current_temperature = 0,
    .set_temperature = 300,
    .next_temperature = 300,
};

volatile uint32_t milliseconds        = 0;

static void init_millisecond_timer(void)
{
    // Set Timer0 to CTC mode
    TCCR0A = (1 << WGM01);

    // Set prescaler to 64
    TCCR0B = (1 << CS01) | (1 << CS00);

    // Set compare value for 1ms interrupt at 1MHz clock
    OCR0A = 15;  // (1MHz / 64 / 1000Hz) - 1

    // Enable Timer0 compare interrupt
    TIMSK0 = (1 << OCIE0A);
}

ISR(TIMER0_COMPA_vect)
{
    ++milliseconds;
}

static uint32_t millis(void)
{
    uint32_t result;
    uint8_t oldSREG = SREG;

    cli();
    result = milliseconds;
    SREG = oldSREG;

    return result;
}

static uint16_t read_temperature_from_eeprom(void)
{
    return eeprom_read_word(TEMPERATURE_EEPROM_ADDRESS);
}

static void write_temperature_to_eeprom(uint16_t temp)
{
    eeprom_update_word(TEMPERATURE_EEPROM_ADDRESS, temp);
}

static void init_buttons(void)
{
    DDRB &= ~((1 << 6) | (1 << 7));
    PCICR |= (1 << PCIE0);
    PCMSK0 |= (1 << PCINT6) | (1 << PCINT7);
    sei();
}

ISR(PCINT0_vect)
{
    static uint8_t last_state = 0;
    static uint32_t last_interrupt_time = 0;

    uint32_t current_time = millis();
    if ((current_time - last_interrupt_time) <= DEBOUNCE_MS)
        return;
    last_interrupt_time = current_time;

    uint8_t current_state = PINB;
    if ((current_state & (1 << PB6)) && !(last_state & (1 << PB6)))
    {
        mode_state.mode += 1;
        switch (mode_state.mode)
        {
        case MODE_SET_100:
            mode_state.next_temperature = mode_state.set_temperature;
            break;
        case MODE_STORE_THEN_RUN:
            mode_state.set_temperature = mode_state.next_temperature;
            write_temperature_to_eeprom(mode_state.set_temperature);
            mode_state.mode = MODE_RUN;
            break;
        }
    }
    if ((current_state & (1 << PB7)) && !(last_state & (1 << PB7)))
    {
        switch (mode_state.mode)
        {
        case MODE_SET_100:
            mode_state.next_temperature = (mode_state.next_temperature + 100)%1000;
            break;
        case MODE_SET_10:
            mode_state.next_temperature = (mode_state.next_temperature/100*100) + ((mode_state.next_temperature + 10)%100);
            break;
        case MODE_SET_1:
            mode_state.next_temperature = (mode_state.next_temperature/10*10) + ((mode_state.next_temperature + 1)%10);
            break;
        }
    }
    last_state = current_state;
}

static void init_temperature_sensor(void)
{
    DDRC &= ~(1 << PC4);

    // Select ADC4 (PC4) as input
    ADMUX = (1 << REFS0) | (1 << MUX2);  // AVCC as reference, ADC4 as input

    // Enable ADC, enable ADC interrupt, set prescaler to 128
    ADCSRA = (1 << ADEN) | (1 << ADIE) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);

    // Free-running mode
    ADCSRB = 0;

    // Disable digital input on ADC4
    DIDR0 = (1 << ADC4D);

    // Start the first conversion
    ADCSRA |= (1 << ADSC);
}

ISR(ADC_vect)
{
    uint16_t adc_value = ADC;
    mode_state.current_temperature = adc_value;

    // Force the next?
    ADCSRA |= (1 << ADSC);
}

static void init_heater(void)
{
    // Set PB1 as output
    DDRB |= (1 << PB1);

    // Set Timer1 to Phase and Frequency Correct PWM mode
    TCCR1B |= (1 << WGM13);

    // Set OC1A (PB1) to non-inverting mode
    TCCR1A |= (1 << COM1A1);

    // Set prescaler to 1
    TCCR1B |= (1 << CS10);

    // Set TOP value for 16-bit resolution
    ICR1 = 65535;

    // Initialize OCR1A to 0 (0% duty cycle)
    OCR1A = 0;
}

static void set_heater_duty(uint16_t duty)
{
    OCR1A = duty;
}

static void init_nixies(void)
{
    DDRD = 0xFF;
    DDRC |= 0x0F;
}

static void set_nixies(uint16_t value, uint16_t flash_mask)
{
    uint8_t low = ((value/10%10) << 4) | (value%10);
    uint8_t high = value/100%10;
    // Blank leading zeroes, but only if we aren't trying to flash any
    if (0 == high && 0 == flash_mask)
    {
        high = 0xF;
        if (0 == (low & 0xF0))
            low |= 0xF0;
    }
    if ((millis()%500) <= 250)
    {
        low |= flash_mask & 0xFF;
        high |= (flash_mask & 0xF00) >> 8;
    }
    PORTD = low;
    PORTC = (PORTC & 0xF0) | high;
}

int main(void)
{
    init_nixies();
    init_buttons();
    init_millisecond_timer();
    init_temperature_sensor();
    init_heater();
    mode_state.set_temperature = read_temperature_from_eeprom();
    sei();

    while (1)
    {
        uint8_t oldSREG = SREG;
        cli();
        mode_state_t read_mode = mode_state;
        SREG = oldSREG;
        switch (read_mode.mode)
        {
        case MODE_RUN:
            set_nixies(read_mode.current_temperature, 0);
            break;
        case MODE_SET_100:
            set_nixies(read_mode.next_temperature, 0xF00);
            break;
        case MODE_SET_10:
            set_nixies(read_mode.next_temperature, 0x0F0);
            break;
        case MODE_SET_1:
            set_nixies(read_mode.next_temperature, 0x00F);
            break;
        }
        _delay_ms(10);
    }

    return 0;
}
