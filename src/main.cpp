#include "stm32h563xx.h"
#include "stm32h5xx_hal.h"

void delay_ms(uint32_t ms) {
    // Basic busy-wait loop, assuming 64 MHz clock (adjust for your system clock)
    // This is ~1ms delay per 64000 iterations (not precise without SysTick)
    for (volatile uint32_t i = 0; i < (64000 * ms); ++i);
}

static void MX_GPIO_Init(void)
{
    __HAL_RCC_GPIOF_CLK_ENABLE();

    /*Configure GPIO pin Output Level */
    HAL_GPIO_WritePin(GPIOF, GPIO_PIN_4, GPIO_PIN_RESET);

    GPIO_InitTypeDef GPIO_InitStruct = {0};
        /*Configure GPIO pin : PB0 */
    GPIO_InitStruct.Pin = GPIO_PIN_4;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);
}

int main() {

    MX_GPIO_Init();

    while (1)
    {
        /* USER CODE END WHILE */
        HAL_GPIO_TogglePin(GPIOF, GPIO_PIN_4);
        HAL_Delay(500);
    }
    
}