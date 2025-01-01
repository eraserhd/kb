#define F_CPU 1000000UL

#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

#define DEBOUNCE_MS  50
#define TEMPERATURE_EEPROM_ADDRESS ((uint16_t*)0)
#define OVERSAMPLE_BITS 3
#define OVERSAMPLE_COUNT (1 << (OVERSAMPLE_BITS*2))
#define EMA_FACTOR 0.8

#define min(x,y) ((x)<(y)?(x):(y))
#define max(x,y) ((x)>(y)?(x):(y))
#define clamp(x,low,high) min(max((x),(low)),(high))
#define interpolate(x,x0,y0,x1,y1) ( ((float)(y0)) + ((x)-(x0)) * (((y1)-(y0))/((x1)-(x0))) )

// Heater PID parameters
#define Kp 0.5f
#define Ki 0.003f
#define Kd -0.05f

#define A_supply_rating         4.0f  // 24V power supply rating
#define A_supply_max            (A_supply_rating - 0.25f)
#define R_heater_25             3.3f
#define R_heater_225            8.8f
#define R_mosfet                0.25f // IRF510 with gate at 5v
#define A_100PCT_DUTY(R_heater) (24.0f/((R_heater)+R_mosfet))
#define MAX_DUTY(R_heater)      min(1.0f, A_supply_max/A_100PCT_DUTY((R_heater)))
#define MAX_DUTY_25             MAX_DUTY(R_heater_25)
#define MAX_DUTY_225            MAX_DUTY(R_heater_225)

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
    float current_temperature;
    float moving_temperature_average;
    uint16_t set_temperature;
    uint16_t next_temperature;
    uint32_t milliseconds;
}
mode_state_t;

volatile mode_state_t mode_state =
{
    .mode = MODE_RUN,
    .current_temperature = 0.0f,
    .moving_temperature_average = 0.0f,
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
    if (mode_state.milliseconds % 250 == 0)
    {
        mode_state.moving_temperature_average =
            EMA_FACTOR * mode_state.moving_temperature_average +
            (1.0 - EMA_FACTOR) * mode_state.current_temperature;
    }
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
        sum >>= OVERSAMPLE_BITS * 2;

        // ADC reads 240 @ 29.7C
        // ADC reads 598 @ 290C
        mode_state.current_temperature = interpolate(
            sum,
            240.0f, 29.7f,
            598.0f, 290.0f
        );

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
    static const float OUTPUT_SCALE = MAX_DUTY_25*65535.0f;

    static float integral = 0.0f;
    static float previous_error = 0.0f;
    static uint32_t last_time = 0;

    if (0.0f == mode_state->current_temperature)
        return;

    // Add a fraction of a degree to set_temperature so we stay away from
    // the "edge" between degrees, to reduce some display flicker.
    float error = (float)mode_state->set_temperature + 0.7f - mode_state->current_temperature;

    if (0 == last_time) {
        last_time = mode_state->milliseconds;
        previous_error = error;
        return;
    }

    uint32_t now = mode_state->milliseconds;
    float dt = max((now - last_time) / 1000.0f, 1.0f);
    last_time = now;

    if (-5.0 < error && error < 5.0)
        integral += error * dt;

    float derivative = (error - previous_error) / dt;
    float output = (Kp * error + Ki * integral + Kd * derivative) * OUTPUT_SCALE;
    previous_error = error;

    // Since the heater resistance increases at hotter temperatures, we
    // can increase the duty cycle at higher temperatures without tripping
    // the supply's overcurrent protection.
    float R_heater = interpolate(
        mode_state->current_temperature,
        25.0f, R_heater_25,
        225.0f, R_heater_225
    );
    float max_output = MAX_DUTY(R_heater) * 65535.0f;
    output = clamp(output, 0, max_output);

    set_heater_duty((uint16_t)output);
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
            set_nixies((uint16_t)read_mode.moving_temperature_average, 0);
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
