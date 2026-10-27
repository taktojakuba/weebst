# st-wl - simple terminal
# See LICENSE file for copyright and license details.

CC = gcc
CFLAGS = -pipe

ifeq (,$(findstring j,$(MAKEFLAGS)))
CPUS ?= $(shell nproc)
MAKEFLAGS += -j $(CPUS)
endif
include config.mk

THISDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ifdef DEBUG
DEBUGFLAGS=-O0 -g -DDEBUG
else
DEBUGFLAGS=-O2
LDFLAGS += -s
endif

SRC = st.c wl.c xdg-shell-protocol.c xdg-decoration-protocol.c primary-selection-protocol.c $(SIXEL_C) $(LIGATURES_C) $(KITTY_GRAPHICS_C)
OBJ = $(SRC:%.c=.objects/%.o)
DEP = $(SRC:%.c=.deps/%.d)

all: st-wl

# Defaults substituted into the man page, read from the config.h st-wl is built with.
MAN_ALPHA = $(or $(shell sed -n 's/^.define DEFAULT_ALPHA[[:space:]]*\([0-9.]*\).*/\1/p' config.h),$(error DEFAULT_ALPHA not found in config.h))
MAN_ALPHA_UNFOCUSED = $(or $(shell sed -n 's/^float alphaUnfocused = \([0-9.]*\);.*/\1/p' config.h),$(error alphaUnfocused not found in config.h))
MAN_UNFOCUSEDPANEBG = $(or $(shell sed -n 's/^int unfocusedpanebg = 0x\([0-9a-fA-F]*\);.*/\1/p' config.h),$(error unfocusedpanebg not found in config.h))
MAN_TERMNAME = $(or $(shell sed -n 's/^char \*termname = "\([^"]*\)";.*/\1/p' config.h),$(error termname not found in config.h))
MAN_TERMCLASS = $(or $(shell sed -n 's/^char \*termclass = "\([^"]*\)";.*/\1/p' config.h),$(error termclass not found in config.h))
MAN_FONTSIZE = $(or $(shell sed -n 's/^.define DEFAULTFONTSIZE[[:space:]]*\([0-9.]*\).*/\1/p' config.h),$(error DEFAULTFONTSIZE not found in config.h))
MAN_COLS = $(or $(shell sed -n 's/^static unsigned int cols = \([0-9]*\);.*/\1/p' config.h),$(error cols not found in config.h))
MAN_ROWS = $(or $(shell sed -n 's/^static unsigned int rows = \([0-9]*\);.*/\1/p' config.h),$(error rows not found in config.h))

options:
	@echo st-wl build options:
	@echo "CFLAGS  = $(STCFLAGS)"
	@echo "LDFLAGS = $(STLDFLAGS)"
	@echo "CC      = $(CC)"
	@touch options

config.h: config.def.h
	cp config.def.h config.h

patches.h: patches.def.h
	cp patches.def.h patches.h

xdg-shell-protocol.c:
	@echo GEN $@
	@wayland-scanner private-code $(XDG_SHELL_PROTO) $@

xdg-shell-client-protocol.h:
	@echo GEN $@
	@wayland-scanner client-header $(XDG_SHELL_PROTO) $@

xdg-decoration-protocol.c:
	@echo GEN $@
	@wayland-scanner private-code $(XDG_DECORATION_PROTO) $@

xdg-decoration-protocol.h:
	@echo GEN $@
	@wayland-scanner client-header $(XDG_DECORATION_PROTO) $@

primary-selection-protocol.c:
	@echo GEN $@
	@wayland-scanner private-code $(PRIMARY_SELECTION_PROTO) $@

primary-selection-client-protocol.h:
	@echo GEN $@
	@wayland-scanner client-header $(PRIMARY_SELECTION_PROTO) $@

ifeq ($(if $(V),$(V),0), 0)
    define quiet
      @echo "  $1 $(notdir $(<:%.c=.objects/%.o))"
      @$(if $2,$2,$($1))
    endef
    define quietlink
      @echo "  $1 $@"
      @$(if $2,$2,$($1))
    endef
else
    define quiet
        $(if $2,$2,$($1))
    endef
    define quietlink
        $(if $2,$2,$($1))
    endef
endif

.objects/%.o .deps/%.d: %.c | .deps .objects
	$(call quiet,CC) $(STCFLAGS) -c $< -o .objects/$*.o -MMD -MP -MF .deps/$*.d -MT .objects/$*.o

.objects/wl.o: xdg-shell-client-protocol.h xdg-decoration-protocol.h primary-selection-client-protocol.h

$(OBJ): config.h config.mk patches.h

# just to make sure that the options rule is run first
$(THISDIR)wld/libwld.a config.h config.mk patches.h: options

st-wl: $(THISDIR)wld/libwld.a $(OBJ)
	$(call quietlink,CC) $(STCFLAGS) -o $@ $(OBJ) $(STLDFLAGS)

$(THISDIR)wld/.objects/%.o:
	@rm -f $@

$(THISDIR)wld/libwld.a:
	@DEBUGFLAGS="$(DEBUGFLAGS)" $(MAKE) -C wld

.deps .objects:
	@mkdir "$@"

clean:
	rm -rf .objects .deps
	rm -f st-wl st-wl-$(VERSION).tar.gz config.h options patches.h xdg-decoration-* xdg-shell-*

	$(MAKE) -C wld clean

install: st-wl
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	rm -f $(DESTDIR)$(PREFIX)/bin/st-wl
	cp -f st-wl $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st-wl
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	@echo cp st-wl.1 $(DESTDIR)$(MANPREFIX)/man1/st-wl.1
	@sed -e "s/VERSION/$(VERSION)/g" \
	    -e "s/@ALPHA@/$(MAN_ALPHA)/g" \
	    -e "s/@ALPHA_UNFOCUSED@/$(MAN_ALPHA_UNFOCUSED)/g" \
	    -e "s/@UNFOCUSEDPANEBG@/$(MAN_UNFOCUSEDPANEBG)/g" \
	    -e "s/@TERMNAME@/$(MAN_TERMNAME)/g" \
	    -e "s/@TERMCLASS@/$(MAN_TERMCLASS)/g" \
	    -e "s/@FONTSIZE@/$(MAN_FONTSIZE)/g" \
	    -e "s/@COLS@/$(MAN_COLS)/g" \
	    -e "s/@ROWS@/$(MAN_ROWS)/g" \
	    < st-wl.1 > $(DESTDIR)$(MANPREFIX)/man1/st-wl.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/st-wl.1
	tic -sx st.info
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	cp st-wl.desktop $(DESTDIR)$(PREFIX)/share/applications
	@echo Please see the README file regarding the terminfo entry of st.

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/st-wl
	rm -f $(DESTDIR)$(MANPREFIX)/man1/st-wl.1
	rm -f $(DESTDIR)$(PREFIX)/share/applications/st-wl.desktop

.PHONY: all clean dist install uninstall

-include wld/.deps/*.d
-include $(DEP)

