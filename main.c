#include <stdbool.h>
#include <stdint.h>
#include "nrf_delay.h"
#include "nrf_gpio.h"
#include <nrfx.h>
#include "nrfx_spi.h"

#define LED NRF_GPIO_PIN_MAP(0,15)

#define PMW3389_REG_PRODUCT_ID                 0x00
#define PMW3389_REG_REVISION_ID                0x01
#define PMW3389_REG_MOTION                     0x02
#define PMW3389_REG_DELTA_X_LOW                0x03
#define PMW3389_REG_DELTA_X_HIGH               0x04
#define PMW3389_REG_DELTA_Y_LOW                0x05
#define PMW3389_REG_DELTA_Y_HIGH               0x06
#define PMW3389_REG_SQUAL                      0x07
#define PMW3389_REG_RAW_DATA_SUM               0x08
#define PMW3389_REG_MAXIMUM_RAW_DATA           0x09
#define PMW3389_REG_MINIMUM_RAW_DATA           0x0A
#define PMW3389_REG_SHUTTER_LOWER              0x0B
#define PMW3389_REG_SHUTTER_UPPER              0x0C
#define PMW3389_REG_CONTROL                    0x0D
#define PMW3389_REG_CONFIG1                    0x0F
#define PMW3389_REG_CONFIG2                    0x10
#define PMW3389_REG_ANGLE_TUNE                 0x11
#define PMW3389_REG_FRAME_CAPTURE              0x12
#define PMW3389_REG_SROM_ENABLE                0x13
#define PMW3389_REG_RUN_DOWNSHIFT              0x14
#define PMW3389_REG_REST1_RATE_LOWER           0x15
#define PMW3389_REG_REST1_RATE_UPPER           0x16
#define PMW3389_REG_REST1_DOWNSHIFT            0x17
#define PMW3389_REG_REST2_RATE_LOWER           0x18
#define PMW3389_REG_REST2_RATE_UPPER           0x19
#define PMW3389_REG_REST2_DOWNSHIFT            0x1A
#define PMW3389_REG_REST3_RATE_LOWER           0x1B
#define PMW3389_REG_REST3_RATE_UPPER           0x1C
#define PMW3389_REG_OBSERVATION                0x24
#define PMW3389_REG_DATA_OUT_LOWER             0x25
#define PMW3389_REG_DATA_OUT_UPPER             0x26
#define PMW3389_REG_RAW_DATA_DUMP              0x29
#define PMW3389_REG_SROM_ID                    0x2A
#define PMW3389_REG_MIN_SQ_RUN                 0x2B
#define PMW3389_REG_RAW_DATA_THRESHOLD         0x2C
#define PMW3389_REG_CONFIG5                    0x2F
#define PMW3389_REG_POWER_UP_RESET             0x3A
#define PMW3389_REG_SHUTDOWN                   0x3B
#define PMW3389_REG_INVERSE_PRODUCT_ID         0x3F
#define PMW3389_REG_LIFTCUTOFF_TUNE3           0x41
#define PMW3389_REG_ANGLE_SNAP                 0x42
#define PMW3389_REG_LIFTCUTOFF_TUNE1           0x4A
#define PMW3389_REG_MOTION_BURST               0x50
#define PMW3389_REG_LIFTCUTOFF_TUNE_TIMEOUT    0x58
#define PMW3389_REG_LIFTCUTOFF_TUNE_MIN_LENGTH 0x5A
#define PMW3389_REG_SROM_LOAD_BURST            0x62
#define PMW3389_REG_LIFT_CONFIG                0x63
#define PMW3389_REG_RAW_DATA_BURST             0x64
#define PMW3389_REG_LIFTCUTOFF_TUNE2           0x65

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
