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

volatile mode_state_t mode_state = {
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
