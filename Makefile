##############################################################################
# Configuration Variables

#Taget Binary Name
TARGET        ?= holonomic-demo

# List all the source files here, or rely on the wildcard
C_SOURCES     ?= $(wildcard src/*.c)
AS_SOURCES    ?= $(wildcard src/*.as)

# Location of local '*.h' files
INCLUDES      ?= inc

# Path to the root of your ARM toolchain
TOOL          ?= $(shell dirname `which arm-none-eabi-gcc`)

# Path to the root of your (Stellaris|Tiva)Ware folder
TW_DIR        ?= $(HOME)/src/StellarisWare

# Path to the root of yor RASLib folder
RAS_DIR				?= $(HOME)/src/C/Rasware/RASLib

# Part Number
Part_Number   ?= LM4F120H5QR

# Location of a linker script
LD_SCRIPT     ?= lm4f.ld

# FPU Type
FPU           ?= softfp

#Debug Makefile mode
Debug         ?= @

# Configuration Variables
###############################################################################


###############################################################################
# Tool Definitions

CC          := $(TOOL)/arm-none-eabi-gcc
LD          := $(TOOL)/arm-none-eabi-ld
AR          := $(TOOL)/arm-none-eabi-ar
AS          := $(TOOL)/arm-none-eabi-as
NM          := $(TOOL)/arm-none-eabi-nm
GDB         := $(TOOL)/arm-none-eabi-gdb
OBJCOPY     := $(TOOL)/arm-none-eabi-objcopy
OBJDUMP     := $(TOOL)/arm-none-eabi-objdump
RANLIB      := $(TOOL)/arm-none-eabi-ranlib
STRIP       := $(TOOL)/arm-none-eabi-strip
SIZE        := $(TOOL)/arm-none-eabi-size
READELF     := $(TOOL)/arm-none-eabi-readelf
DEBUG       := $(TOOL)/arm-none-eabi-gdb
CP          := cp -p
RM          := rm -rf
MV          := mv
MKDIR       := mkdir -p
UART	    := screen

# Tool Definitions
###############################################################################


###############################################################################
# Flag Definitions

# both C and ASM flags
FLAGS      += -mthumb
FLAGS      += -mcpu=cortex-m4
FLAGS      += -mfloat-abi=$(FPU)
FLAGS      += -mfpu=fpv4-sp-d16

AFLAGS     += ${FLAGS}
CFLAGS     += ${FLAGS}

# C only Flags
CFLAGS     += -MD
CFLAGS     += -Wall
CFLAGS     += -Wextra
CFLAGS     += -Werror
CFLAGS     += -Wno-deprecated-declarations
CFLAGS     += -pedantic
CFLAGS     += -DPART_${Part_Number}
CFLAGS     += -Dgcc
CFLAGS     += -DTARGET_IS_BLIZZARD_RA1
CFLAGS     += -std=gnu99
CFLAGS     += -g
CFLAGS     += -gdwarf-2
CFLAGS     += -g3
CFLAGS     += -ffunction-sections
CFLAGS     += -fdata-sections
CFLAGS     += -fsingle-precision-constant
CFLAGS     += -I$(TW_DIR)/.. -I$(INCLUDES) -I$(RAS_DIR)/..
CFLAGS     += -O3

LIBS	   += ras
LIBS     += driver-cm4f
LIBS	   += m
LIBS	   += c
LIBS	   += gcc

LDFLAGS	   += -L ${TW_DIR}/driverlib/gcc-cm4f
LDFLAGS	   += -L ${RAS_DIR}/output

LDFLAGS    += $(addprefix -L , $(shell ${CC} ${CFLAGS} -print-search-dirs | grep libraries | sed -e 's/libraries:\ =//' -e 's/:/ /g'))

LDFLAGS    += --gc-sections
LDFLAGS    += -nostdlib
# Flag Definitions
###############################################################################


###############################################################################
# Boilerplate

# Create the Directories we need
$(eval $(shell	$(MKDIR) bin))

# Object File Directory, keeps things tidy
OBJECTS    := $(patsubst src/%.c, bin/%.o, $(C_SOURCES))
OBJECTS    += $(patsubst src/%.as, bin/%.o, $(AS_SOURCES))
ASMS       := $(patsubst src/%.c, bin/%.s, $(C_SOURCES))

all:

# Include dependency info, if we have it
-include ${OBJECTS:.o=.d}

# Boilerplate
###############################################################################


###############################################################################
# Command Definitions, Dragons Ahead

all: bin/$(TARGET).out

asm: $(ASMS)

# Compiler Command
bin/%.o: src/%.c
	${Debug}echo CC: $<
	${Debug}$(CC) -c $(CFLAGS) -o $@ $< -MT $@ -MT ${@:.o=.s}

# Assember Command
bin/%.o: src/%.as
	${Debug}echo AS: $<
	${Debug}$(AS) -c $(AFLAGS) -o $@ $<

# Create Assembly
bin/%.s: src/%.c
	${Debug}echo C "->" AS: $<
	${Debug}$(CC) -S $(CFLAGS) -o $@ $< -MT ${@:.s=.o} -MT $@

# Linker Command
bin/$(TARGET).out: $(OBJECTS) ${LD_SCRIPT}
	${Debug}echo LD: $^
	${Debug}$(LD) $(LDFLAGS) -T $(LD_SCRIPT) -o $@ $(OBJECTS) $(patsubst %,-l%, ${LIBS})

size: bin/$(TARGET).out
	${Debug}$(SIZE) $<

clean:
	${Debug}$(RM) bin

.gdb-script: 
	${Debug}echo "target remote | openocd -c \"source [find board/ek-lm4f120xl.cfg]\" -c \"gdb_port pipe; log_output openocd.log\""> $@
	${Debug}echo "monitor reset halt" >> $@
	${Debug}echo "load" >> $@
	${Debug}echo "monitor reset halt" >> $@

debug: bin/${TARGET}.out .gdb-script
	${Debug}${GDB} $< -x .gdb-script ${GDBFLAGS}

flash: debug
flash: GDBFLAGS += -ex "monitor reset run" -batch

uart: flash
	${Debug}${UART} /dev/lm4f 115200

# Command Definitions, Dragons Ahead
###############################################################################
