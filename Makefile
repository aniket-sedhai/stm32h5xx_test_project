# Toolchain
CC      = arm-none-eabi-gcc
CXX     = arm-none-eabi-g++
AS      = arm-none-eabi-as
LD      = arm-none-eabi-g++
OBJCOPY = arm-none-eabi-objcopy
SIZE    = arm-none-eabi-size

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
HAL_OBJS = $(patsubst $(HAL_DIR)/Src/%.c, $(BUILD_DIR)/%.o, $(HAL_SRC))
INCLUDE_DIRS = -Iinclude -I$(SYSTEM_DIR) -IDrivers/CMSIS/Include -IDrivers/CMSIS/Device/ST/STM32H5xx/Include -I$(HAL_DIR)/Inc

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

$(BUILD_DIR)/%.o: $(HAL_DIR)/Src/%.c | $(BUILD_DIR)
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