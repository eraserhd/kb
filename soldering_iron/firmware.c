#define F_CPU 1000000UL

#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define DEBOUNCE_MS  50

enum
{
    MODE_RUN     = 0,
    MODE_SET_100,
    MODE_SET_10,
    MODE_SET_1,
    MODE_LAST,
};

static uint8_t  mode                = MODE_RUN;
static uint16_t current_temperature = 0;
static uint16_t set_temperature     = 300;
static uint16_t next_temperature    = 300;

static void init_buttons(void)
{
    DDRB &= ~((1 << 6) | (1 << 7));
    PCICR |= (1 << PCIE0);
    PCMSK0 |= (1 << PCINT6) | (1 << PCINT7);
    sei();
}

ISR(PCINT0_vect)
{
    ++current_temperature;

    if (PINB & (1 << PB6))
    {
        mode += 1;
        if (MODE_LAST == mode)
            mode = MODE_RUN;
    }

    if (PINB & (1 << PB7))
    {
        switch (mode)
        {
        case MODE_SET_100:
            next_temperature = (next_temperature + 100)%1000;
            break;
        case MODE_SET_10:
            next_temperature = (next_temperature/100*100) + ((next_temperature + 10)%100);
            break;
        case MODE_SET_1:
            next_temperature = (next_temperature/10*10) + ((next_temperature + 1)%10);
            break;
        }
    }
}

static void init_nixies(void)
{
    DDRD = 0xFF;
    DDRC |= 0x0F;
}

static void set_nixies(uint16_t value)
{
    uint8_t low = ((value/10%10) << 4) | (value%10);
    uint8_t high = value/100%10;
    if (0 == high)
    {
        high = 0xF;
        if (0 == (low & 0xF0))
            low |= 0xF0;
    }
    PORTD = low;
    PORTC = (PORTC & 0xF0) | high;
}

int main(void)
{
    init_nixies();
    init_buttons();

    while (1)
    {
        switch (mode)
        {
        case MODE_RUN:
            set_nixies(current_temperature);
            break;
        case MODE_SET_100:
            set_nixies(next_temperature);
            break;
        case MODE_SET_10:
            set_nixies(next_temperature);
            break;
        case MODE_SET_1:
            set_nixies(next_temperature);
            break;
        }
        _delay_ms(1000);
    }

    return 0;
}
