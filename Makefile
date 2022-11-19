CA65_BINARY= ca65
CA65_FLAGS= --cpu 65c02 -t none
LD65_BINARY= ld65
LD65_FLAGS=
AR65_BINARY= ar65
AR65_FLAGS= r
MKDIR_BINARY= mkdir
MKDIR_FLAGS= -v -p

FIRMWARE= firmware.basic.cfg

BUILD= build

# COMMON STUFF
COMMON_ROOT= common
COMMON_SOURCES= $(COMMON_ROOT)/source
COMMON_INCLUDES= $(COMMON_ROOT)/include
COMMON_BUILD= $(BUILD)/common
COMMON_SOURCE_FILES= io.s \
			acia.s \
			lcd.s \
			utils.s \
			xmodem.s \
			zeropage.s
COMMON_OBJECTS=$(COMMON_SOURCE_FILES:%.s=$(COMMON_BUILD)/%.o)
COMMON_LIB=$(COMMON_BUILD)/common.lib

# ROM STUFF
ROM_ROOT= rom
ROM_BUILD= $(BUILD)/rom
ROM_SOURCES= $(ROM_ROOT)
ROM_SOURCE_FILES= 01_blink.s \
			02_lcd.s \
			03_acia_echo.s
ROM_OBJECTS=$(ROM_SOURCE_FILES:%.s=$(ROM_BUILD)/%.o)
ROM_BINARIES=$(ROM_SOURCE_FILES:%.s=$(ROM_BUILD)/%.bin)

# Don't edit beyond this line.

phony: clean all
clean:
	rm -frv $(BUILD)/*

all: $(COMMON_LIB) $(ROM_BINARIES)
	@echo "Building everything."

# all the fancy makefile stuff here.
# Build the common libraries
$(COMMON_BUILD)/%.o: $(COMMON_SOURCES)/%.s
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(COMMON_BUILD)
	$(CA65_BINARY) $(CA65_FLAGS) -I $(COMMON_INCLUDES) -l $(@:.o=.lst) -o $(@:.s=.o) $^

# pack up the common library
$(COMMON_BUILD)/common.lib: $(COMMON_OBJECTS)
	$(AR65_BINARY) $(AR65_FLAGS) $(COMMON_LIB) $^

# Build the roms
$(ROM_BUILD)/%.o: $(ROM_SOURCES)/%.s
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(ROM_BUILD)
	$(CA65_BINARY) $(CA65_FLAGS) -I $(COMMON_INCLUDES) -l $(@:.o=.lst)  -o $(@:.s=.o) $^

# Link the roms
$(ROM_BUILD)/%.bin: $(ROM_OBJECTS) $(COMMON_LIB)
	$(LD65_BINARY) $(LD65_FLAGS) -C $(FIRMWARE) -m $(@:.bin=.map)  -o $@ $(@:.bin=.o) $(COMMON_LIB)
