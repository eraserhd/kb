#ifndef custom_board_h_INCLUDED
#define custom_board_h_INCLUDED

/*
 * Basically all this file does is tell where the LED is on the nice!nano.
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "nrf_gpio.h"

// LED definitions for PCA10059
// Each LED color is considered a separate LED
#define LEDS_NUMBER    1

#define LED1_B         NRF_GPIO_PIN_MAP(0,15)
#define LED_1          LED1_B

#define LEDS_ACTIVE_STATE 0

#define LEDS_LIST { LED_1 }

#define LEDS_INV_MASK  LEDS_MASK

#define BSP_LED_0      LED_1

#define BUTTONS_NUMBER 0

#define BUTTONS_ACTIVE_STATE 0

#define BUTTONS_LIST { }

#define BSP_SELF_PINRESET_PIN NRF_GPIO_PIN_MAP(0,14)

#define HWFC           true

#ifdef __cplusplus
}
#endif

#endif // custom_board_h_INCLUDED
