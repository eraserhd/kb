#define F_CPU 1000000UL

#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define DEBOUNCE_MS  50
#define TEMPERATURE_EEPROM_ADDRESS ((uint16_t*)0)
#define OVERSAMPLE_BITS 3
#define OVERSAMPLE_COUNT (1 << (OVERSAMPLE_BITS*2))

#define min(x,y) ((x)<(y)?(x):(y))
#define max(x,y) ((x)>(y)?(x):(y))
#define clamp(x,low,high) min(max((x),(low)),(high))

// Heater PID parameters
#define Kp 0.5f
#define Ki 0.0f
#define Kd 0.0f

#define A_supply_rating 4.0f  // 24V power supply rating
#define A_supply_max    (A_supply_rating - 0.25f)
#define R_heater_25     3.3f  // low end of heater resistance
#define R_mosfet        0.25f // IRF510 with gate at 5v
#define A_100pct_duty   (24.0f/(R_heater_25+R_mosfet))
#define MAX_DUTY        min(1.0f, A_supply_max/A_100pct_duty)

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
    uint32_t milliseconds;
}
mode_state_t;

volatile mode_state_t mode_state =
{
    .mode = MODE_RUN,
    .current_temperature = 0,
    .set_temperature = 300,
    .next_temperature = 300,
    .milliseconds = 0,
};

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
    ++mode_state.milliseconds;
}

static uint32_t millis(void)
{
    uint32_t result;
    uint8_t oldSREG = SREG;

    cli();
    result = mode_state.milliseconds;
    SREG = oldSREG;

    return result;
}

static uint16_t read_temperature_from_eeprom(void)
{
    uint16_t result = eeprom_read_word(TEMPERATURE_EEPROM_ADDRESS);
    return 0xFFFF == result ? 300 : result;
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

    // Select ADC4 (PC4) as input with internal 1.1V reference
    ADMUX = (1 << REFS0) | (1 << REFS1) | (4 & 0x0F);
    _delay_ms(1); // Let voltage settle

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
    static uint8_t count = OVERSAMPLE_COUNT;
    static uint16_t sum = 0;
    sum += ADC;
    if (--count == 0)
    {
        // 27  = 53.93x + b  (R = 53.93 Ohms at 27 C)
        // 525 = 223.7x + b  (R = 223.7 Ohms at 525 C)
        // --
        // 27 - 525 = 53.93x - 223.7x
        // -498 = -169.77x
        // 2.933 = x

        // 27 = 53.93 * 2.933 + b
        // 27 - 158.18 = b
        // -131.18 = b

        // So C = 2.933R - 131.18

        // 1000 ohms on top resistor, R on the bottom resistor, and we
        // are measuring steps from GND to 1.1v (the top resistor is connected

        // V = 5(R / (1000+R))  (FIXME: actual voltage is 4.9#?)
        // V/5 = R/(1000+R)
        // x = V/5; x = R/(1000+R)
        // x = v/5; x(1000+R) = R
        // x = v/5; 1000x+Rx = R
        // x = v/5; 1000x = R - Rx
        // x = v/5; 1000x = R(1-x)
        // x = v/5; 1000x/(1-x) = R
        // 1000(v/5)/(1-v/5) = R

        // A = (V/1.1)*1024
        // A/1024 = V/1.1
        // 11*(A/10240) = V
        // V = A*(11/10240)

        // C = 2.933 * ((A*(11/10240))/5) / (1-(A*(11/10240))/5) - 131
        // C = 2.933 * (A*(11/51200)) / (1-(A*(11/51200))) - 131

        // A / 1024 / 1.1 = R / (1000+R), so
        // R = 1000 * (A / 1024 / 1.1) / (1 - (A / 1024 / 1.1))
        // R = (1000 * A) / (1024 * 1.1 * (1 - A / 1024 / 1.1))
        // R = (1000 * A) / (1024 * 1.1 - A)
        // R = (1000 * A) / (1126.4 - A)

        // Combining the equations:
        // C = 2.933(1000*A/(1126.4 - A)) - 131.18
        // C = 2933*A/(1126.4 - A) - 131

        uint16_t A = sum >> (OVERSAMPLE_BITS * 2);
        float V = A*11/10240.0;
        float R = 1000.0*(V/5.0)/(1.0-V/5.0);
        float C = 2.933*R - 131.18;

        mode_state.current_temperature = C;

        //mode_state.current_temperature = 2933*((uint32_t)A)/(1126 - A) - 131;
        sum = 0;
        count = OVERSAMPLE_COUNT;
    }

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

void adjust_heater_pwm(mode_state_t *mode_state)
{
    static const float OUTPUT_SCALE = MAX_DUTY*65535.0f;

    static float integral = 0.0f;
    static float previous_error = 0.0f;
    static uint32_t last_time = 0;

    float error = mode_state->set_temperature - mode_state->current_temperature;

    if (0 == last_time) {
        last_time = mode_state->milliseconds;
        previous_error = error;
        return;
    }

    uint32_t now = mode_state->milliseconds;
    float dt = max((now - last_time) / 1000.0f, 1.0f);
    last_time = now;

    integral += error * dt;
    integral = clamp(integral, -10000, 10000);

    float derivative = error - previous_error;
    float output = (Kp * error + Ki * integral + Kd * derivative) * OUTPUT_SCALE;
    previous_error = error;

    set_heater_duty((uint16_t)clamp(output, 0, OUTPUT_SCALE));
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
        adjust_heater_pwm(&read_mode);
        _delay_ms(10);
    }

    return 0;
}
