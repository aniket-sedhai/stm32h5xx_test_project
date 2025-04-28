# Toolchain
CC      = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-gcc
CXX     = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-g++
AS      = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-as
LD      = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-g++
OBJCOPY = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy
SIZE    = /Applications/ARM-GCC/gcc-arm-none-eabi/bin/arm-none-eabi-size

# MCU flags
MCU       = cortex-m33
FPU       = fpv5-sp-d16
FLOAT_ABI = hard

# Directories
BUILD_DIR  = build
SRC_DIR    = src
DUMMY_DIR  = $(SRC_DIR)/dummy
SYSTEM_DIR = system
HAL_DIR = Drivers/STM32H5xx_HAL_Driver
HAL_SRC = $(wildcard $(HAL_DIR)/Src/*.c)
HAL_OBJS = $(foreach f,$(notdir $(HAL_SRC)),$(BUILD_DIR)/$(f:.c=.o))
INCLUDE_DIRS = -Iinclude -Isrc/FreeRTOS-Kernel/include -Isrc/FreeRTOS-Kernel/portable/GCC/ARM_CM33_NTZ/non_secure -I/Applications/ARM-GCC/gcc-arm-none-eabi/arm-none-eabi/include -I$(SYSTEM_DIR) -IDrivers/CMSIS/Include -IDrivers/CMSIS/Device/ST/STM32H5xx/Include -I$(HAL_DIR)/Inc

# Files
LINKER_SCRIPT = linker/STM32H563ZITx_FLASH.ld
STARTUP_OBJ   = $(BUILD_DIR)/startup_stm32h563xx.o
OBJS = \
	$(BUILD_DIR)/main.o \
	$(BUILD_DIR)/system_stm32h5xx.o \
	$(STARTUP_OBJ) \
	$(BUILD_DIR)/dummy_functions.o \
	$(HAL_OBJS)


# Flags
COMMON_FLAGS = -mcpu=$(MCU) -mthumb -mfpu=$(FPU) -mfloat-abi=$(FLOAT_ABI) -Wall -ffunction-sections -fdata-sections -g -DSTM32H563xx $(INCLUDE_DIRS)
CFLAGS   = $(COMMON_FLAGS) -std=c99
CXXFLAGS = $(COMMON_FLAGS) -std=c++17 -fno-exceptions -fno-rtti -fno-use-cxa-atexit -fno-threadsafe-statics
ASFLAGS  = -mcpu=$(MCU) -mthumb
LDFLAGS  = -T$(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,-e,Reset_Handler -Wl,-Map=$(BUILD_DIR)/firmware.map -static

# Targets
TARGET_ELF = $(BUILD_DIR)/firmware.elf
TARGET_BIN = $(BUILD_DIR)/firmware.bin
TARGET_HEX = $(BUILD_DIR)/firmware.hex

all: $(TARGET_ELF)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/dummy_functions.o: $(DUMMY_DIR)/dummy_functions.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/main.o: $(SRC_DIR)/main.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/system_stm32h5xx.o: $(SYSTEM_DIR)/system_stm32h5xx.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@


# FreeRTOS objects
FREERTOS_DIR = Middlewares/Third_Party/FreeRTOS/Source
FREERTOS_OBJS = \
    $(BUILD_DIR)/list.o \
    $(BUILD_DIR)/queue.o \
    $(BUILD_DIR)/tasks.o \
    $(BUILD_DIR)/timers.o \
    $(BUILD_DIR)/heap_4.o \
    $(BUILD_DIR)/port.o

# HAL object files (flattened)
$(BUILD_DIR)/%.o: $(HAL_DIR)/Src/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# FreeRTOS source files (explicit rules, flattened)
$(BUILD_DIR)/list.o: $(FREERTOS_DIR)/list.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/queue.o: $(FREERTOS_DIR)/queue.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/tasks.o: $(FREERTOS_DIR)/tasks.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/timers.o: $(FREERTOS_DIR)/timers.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/heap_4.o: $(FREERTOS_DIR)/portable/MemMang/heap_4.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/port.o: $(FREERTOS_DIR)/portable/GCC/ARM_CM33_NTZ/port.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(STARTUP_OBJ): $(SRC_DIR)/startup_stm32h563xx.s | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(TARGET_ELF): $(OBJS)
	$(LD) $(CXXFLAGS) $(OBJS) -o $@ $(LDFLAGS)
	$(OBJCOPY) -O ihex   $@ $(TARGET_HEX)
	$(OBJCOPY) -O binary $@ $(TARGET_BIN)
	$(SIZE) $@

clean:
	rm -rf $(BUILD_DIR)

flash: $(TARGET_HEX)
	STM32_Programmer_CLI --connect port=SWD --download $(TARGET_HEX) 0x08000000 --verify --start