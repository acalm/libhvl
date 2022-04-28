check_gcc = $(shell if echo | $(CC) $(1) -Werror -S -o /dev/null -xc - > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi;)

# ---------------------------

HOST_OS := $(shell uname|sed -e s/_.*//|tr '[:upper:]' '[:lower:]')

DEBUG   ?= 0

# ---------------------------
# build variables
# ---------------------------

CC ?= gcc
LINKER = $(CC)

STRIP ?= strip

CPUFLAGS=
DFLAGS ?=
CFLAGS ?=
CFLAGS += -pipe -Ihvl/ -Wall -std=gnu11 -fPIC
CFLAGS += $(CPUFLAGS)
ifneq ($(DEBUG),0)
DFLAGS += -D_DEBUG
CFLAGS += -g
do_strip=
else
DFLAGS += -DNDEBUG
CFLAGS += -O2
CFLAGS += $(call check_gcc,-fweb,)
CFLAGS += $(call check_gcc,-frename-registers,)
cmd_strip=$(STRIP) $(1)
define do_strip
	$(call cmd_strip,$(1));
endef
endif

SDL_CONFIG ?= sdl2-config
SDL_CFLAGS := $(shell $(SDL_CONFIG) --cflags)
SDL_LIBS   := $(shell $(SDL_CONFIG) --libs)
COMMON_LIBS:= -lm
LIBS := $(COMMON_LIBS)

# ---------------------------
# targets
# ---------------------------

.PHONY:	clean debug release

DEFAULT_TARGET := release

# ---------------------------
# rules
# ---------------------------

%.o:	hvl/%.c
	$(CC) $(DFLAGS) -c $(CFLAGS) $(SDL_CFLAGS) -o $@ $^

# ----------------------------------------------------------------------------
# objects
# ----------------------------------------------------------------------------


OBJS := hvl_replay.o \
		play_hvl.o \
	$(SYSOBJ_SYS) $(SYSOBJ_MAIN) $(SYSOBJ_RES)

play_hvl:	$(OBJS)
	$(LINKER) $(OBJS) $(LDFLAGS) $(LIBS) $(SDL_LIBS) -o $@
	$(call do_strip,$@)

hvl_replay.so: $(OBJS)
	$(CC) $(CFLAGS) $(SDL_CFLAGS) hvl/hvl_replay.c -o $@ -shared
	$(call do_strip,$@)

release:	play_hvl
debug:
	$(error Use "make DEBUG=1")

clean:
	rm -f $(shell find . \( -name '*~' -o -name '*.so' -o -name '#*#' -o -name '*.o' -o -name '*.res' -o -name $(DEFAULT_TARGET) \) -print)
