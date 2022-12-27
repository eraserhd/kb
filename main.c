#include <stdbool.h>
#include <stdint.h>
#include "nrf_delay.h"
#include "nrf_gpio.h"

#define LED NRF_GPIO_PIN_MAP(0,15)

#define SPI_SCK    NRF_GPIO_PIN_MAP(0,17)
#define SPI_SDO    NRF_GPIO_PIN_MAP(0,8)
#define SPI_SDI    NRF_GPIO_PIN_MAP(0,6)
#define PMW3389_CS NRF_GPIO_PIN_MAP(0,20)

int main(void)
{
    nrf_gpio_cfg_output(LED);

    nrf_gpio_cfg_output(PMW3389_CS);
    nrf_gpio_pin_write(PMW3389_CS, 1);

    while (true)
    {
        nrf_gpio_pin_toggle(LED);
        nrf_delay_ms(2000);
    }
}
