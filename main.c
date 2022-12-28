#include <stdbool.h>
#include <stdint.h>
#include "nrf_delay.h"
#include "nrf_gpio.h"
#include <nrfx.h>
#include "nrfx_spi.h"

#define LED NRF_GPIO_PIN_MAP(0,15)

#define PMW3389_REG_MOTION         0x02
#define PMW3389_REG_DELTA_X_LOW    0x03
#define PMW3389_REG_DELTA_X_HIGH   0x04
#define PMW3389_REG_DELTA_Y_LOW    0x05
#define PMW3389_REG_DELTA_Y_HIGH   0x06
#define PMW3389_REG_POWER_UP_RESET 0x3A

#define SPI_SCK    NRF_GPIO_PIN_MAP(0,17)
#define SPI_SDO    NRF_GPIO_PIN_MAP(0,8)
#define SPI_SDI    NRF_GPIO_PIN_MAP(0,6)
#define PMW3389_CS NRF_GPIO_PIN_MAP(0,20)

static const nrfx_spi_config_t spi_config = {
    .sck_pin = NRF_GPIO_PIN_MAP(0,17),
    .mosi_pin = NRF_GPIO_PIN_MAP(0,6),
    .miso_pin = NRF_GPIO_PIN_MAP(0,8),
    .ss_pin = NRF_GPIO_PIN_MAP(0,20),
    .frequency = NRF_SPI_FREQ_125K,
    .mode = NRF_SPI_MODE_3,
    .bit_order = NRF_SPI_BIT_ORDER_MSB_FIRST,
};

static const nrfx_spi_t spi = NRFX_SPI_INSTANCE(0);

int32_t pmw3389_read_reg8(nrfx_spi_t const* spi, uint8_t reg)
{
    uint8_t buf[2] = {};
    nrfx_spi_xfer_desc_t xfer = NRFX_SPI_SINGLE_XFER(&reg, 1, buf, 2);
    if (NRFX_SUCCESS != nrfx_spi_xfer(spi, &xfer, 0))
    {
        return -1;
    }
    return buf[1];
}

int32_t pmw3389_read_reg16(nrfx_spi_t const* spi, uint8_t low, uint8_t high)
{
    int low_part = 0, high_part = 0;
    if (-1 == (low_part = pmw3389_read_reg8(spi, low)))
    {
        return -1;
    }
    if (-1 == (high_part = pmw3389_read_reg8(spi, high)))
    {
        return -1;
    }
    // will this handle sign extension?
    return (int16_t)(((uint16_t)high_part) << 8 | ((uint16_t)low_part));
}

int main(void)
{
    nrf_gpio_cfg_output(LED);
    nrf_gpio_pin_clear(LED);

    if (NRFX_SUCCESS != nrfx_spi_init(&spi, &spi_config, NULL, NULL))
    {
        nrf_gpio_pin_set(LED);
        return -1;
    }

    static const uint8_t reset[] = {PMW3389_REG_POWER_UP_RESET, 0x5a};
    nrfx_spi_xfer_desc_t xfer = NRFX_SPI_XFER_TX(reset, 2);
    if (NRFX_SUCCESS != nrfx_spi_xfer(&spi, &xfer, 0))
    {
        nrf_gpio_pin_set(LED);
        return -1;
    }

    // Wait for reboot
    nrf_delay_ms(50);

    if (-1 == pmw3389_read_reg8(&spi, PMW3389_REG_MOTION))
    {
        nrf_gpio_pin_set(LED);
        return -1;
    }
    if (-1 == pmw3389_read_reg16(&spi, PMW3389_REG_DELTA_X_LOW, PMW3389_REG_DELTA_X_HIGH))
    {
        nrf_gpio_pin_set(LED);
        return -1;
    }
    if (-1 == pmw3389_read_reg16(&spi, PMW3389_REG_DELTA_Y_LOW, PMW3389_REG_DELTA_Y_HIGH))
    {
        nrf_gpio_pin_set(LED);
        return -1;
    }

    while (true)
    {
        nrf_delay_ms(2000);
    }
}
