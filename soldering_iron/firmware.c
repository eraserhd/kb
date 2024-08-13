#define F_CPU 1000000UL

#include <avr/io.h>
#include <util/delay.h>

static void init_nixies(void)
{
    DDRD = 0xFF;
    DDRC |= 0x0F;
}

static void set_nixies(uint16_t value)
{
    PORTD = ((value/10%10) << 4) | (value%10);
    PORTC = (PORTC & 0xF0) | (value/100%10);
}

int main(void)
{
    init_nixies();

    uint16_t value = 42;

    while (1)
    {
        set_nixies(value);
        value = (value + 111)%1000;
        _delay_ms(3000);
    }

    return 0;
}
