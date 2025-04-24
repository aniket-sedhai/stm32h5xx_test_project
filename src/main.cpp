#include "stm32h563xx.h"
#include <stdint.h>

void delay_ms(uint32_t ms) {
    // Basic busy-wait loop, assuming 64 MHz clock (adjust for your system clock)
    // This is ~1ms delay per 64000 iterations (not precise without SysTick)
    for (volatile uint32_t i = 0; i < (64000 * ms); ++i);
}

int main() {
    // Enable clock for GPIOB
    RCC->AHB4ENR |= RCC_AHB2ENR_GPIOBEN;

    // Set PB0 as general-purpose output (01)
    GPIOB->MODER &= ~(0b11 << (0 * 2));  // Clear mode bits
    GPIOB->MODER |=  (0b01 << (0 * 2));  // Set to output mode

    // Optional: Set output type to push-pull (default)
    GPIOB->OTYPER &= ~(1 << 0);

    // Optional: Set no pull-up/pull-down
    GPIOB->PUPDR &= ~(0b11 << (0 * 2));

    while (1) {
        GPIOB->ODR ^= (1 << 0); // Toggle PB0
        delay_ms(500);
    }
}