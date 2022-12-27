#include <stdbool.h>
#include <stdint.h>
#include "nrf_delay.h"
#include "nrf_gpio.h"

#define LED NRF_GPIO_PIN_MAP(0,15)

int main(void)
{
    nrf_gpio_cfg_output(LED);
    while (true)
    {
        nrf_gpio_pin_toggle(LED);
        nrf_delay_ms(2000);
    }
}
