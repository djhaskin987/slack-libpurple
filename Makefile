C_SRCS = slack.c \
	 slack-cmd.c \
	 slack-message.c \
	 slack-auth.c \
	 slack-thread.c \
	 slack-conversation.c \
	 slack-channel.c \
	 slack-im.c \
	 slack-user.c \
	 slack-rtm.c \
	 slack-blist.c \
	 slack-api.c \
	 slack-object.c \
	 slack-json.c \
	 purple-websocket.c \
	 json.c

# Object file names using 'Substitution Reference'
C_OBJS = $(C_SRCS:.c=.o)


PURPLE_MOD=purple

# https://stackoverflow.com/a/52062069/850326
ifeq '$(findstring ;,$(PATH))' ';'
OS := Windows
else
OS := $(shell uname 2>/dev/null || echo Unknown)
OS := $(patsubst CYGWIN%,Cygwin,$(OS))
OS := $(patsubst MSYS%,MSYS,$(OS))
OS := $(patsubst MINGW%,MSYS,$(OS))
endif

ifeq ($(OS),MSYS)
LIBNAME=libslack.dll
PIDGIN_TREE_TOP ?= ../pidgin-2.10.11
WIN32_DEV_TOP ?= $(PIDGIN_TREE_TOP)/../win32-dev
CC = gcc 
PROGFILES32 = ${ProgramFiles(x86)}
ifndef PROGFILES32
PROGFILES32 = $(PROGRAMFILES)
endif
LOCALEDIR = "$(PROGFILES32)/Pidgin/locale"
PROGFILES32=${ProgramFiles(x86)}
ifndef PROGFILES32
PROGFILES32=$(PROGRAMFILES)
endif
PLU = libgroupme.dll
PLUGIN_DIR_PURPLE = "$(PROGFILES32)/Pidgin/plugins"
LOCALEDIR = "$(PROGFILES32)/Pidgin/locale"
DATA_ROOT_DIR_PURPLE:="$(PROGFILES32)/Pidgin"
CFLAGS = \
	-g \
	-O2 \
	-Wall \
	-Wno-error=strict-aliasing \
	-Wstringop-truncation \
	-D_DEFAULT_SOURCE=1 \
    -D_XOPEN_SOURCE=1 \
	-DMSYS2 \
	-std=c99 \
	-I/mingw64/include/libpurple/ \
	-I/mingw64/include/json-glib-1.0/ \
	-I/mingw64/include/pidgin/win32 \
	-I/mingw64/include/pidgin/ \
	-I/mingw64/lib/glib-2.0/include/ \
	-I/mingw64/include/glib-2.0/ \
	-pipe
LIBS = \
	   -lpurple \
	   -lintl \
	   -lglib-2.0 \
	   -lgobject-2.0 \
	   -g \
	   -ggdb \
	   -static-libgcc \
	   -lz \
	   -lws2_32 

else ifeq ($(OS),Windows)

LIBNAME=libslack.dll
PIDGIN_TREE_TOP ?= ../pidgin-2.10.11
WIN32_DEV_TOP ?= $(PIDGIN_TREE_TOP)/../win32-dev
WIN32_CC ?= $(WIN32_DEV_TOP)/mingw-4.7.2/bin/gcc

PROGFILES32=${ProgramFiles(x86)}
ifndef PROGFILES32
PROGFILES32=$(PROGRAMFILES)
endif

CC = $(WIN32_DEV_TOP)/mingw-4.7.2/bin/gcc

DATA_ROOT_DIR_PURPLE:="$(PROGFILES32)/Pidgin"
PLUGIN_DIR_PURPLE:="$(DATA_ROOT_DIR_PURPLE)/plugins"
CFLAGS = \
    -g \
    -O2 \
    -Wall \
    -D_DEFAULT_SOURCE=1 \
    -D_XOPEN_SOURCE=1 \
    -std=c99 \
	-I$(PIDGIN_TREE_TOP)/libpurple \
	-I$(WIN32_DEV_TOP)/glib-2.28.8/include -I$(WIN32_DEV_TOP)/glib-2.28.8/include/glib-2.0 -I$(WIN32_DEV_TOP)/glib-2.28.8/lib/glib-2.0/include
LIBS = -L$(WIN32_DEV_TOP)/glib-2.28.8/lib -L$(PIDGIN_TREE_TOP)/libpurple -lpurple -lintl -lglib-2.0 -lgobject-2.0 -g -ggdb -static-libgcc -lz -lws2_32 


else

LIBNAME=libslack.so

CC=gcc
PLUGIN_DIR_PURPLE:=$(DESTDIR)$(shell pkg-config --variable=plugindir $(PURPLE_MOD))
DATA_ROOT_DIR_PURPLE:=$(DESTDIR)$(shell pkg-config --variable=datarootdir $(PURPLE_MOD))
PKGS=$(PURPLE_MOD) glib-2.0 gobject-2.0

CFLAGS = \
    -g \
    -O2 \
    -Wall -Werror \
    -Wno-error=strict-aliasing \
    -fPIC \
    -D_DEFAULT_SOURCE=1 \
    -std=c99 \
    $(shell pkg-config --cflags $(PKGS))

LIBS = $(shell pkg-config --libs $(PKGS))

endif

.PHONY: all
all: $(LIBNAME) 

LDFLAGS = -shared

json.%: json-parser/json.%
	cp $< $@

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
%.E: %.c
	$(CC) -E $(CFLAGS) -o $@ $<

$(LIBNAME): $(C_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

.PHONY: install install-user
install: $(LIBNAME)
	install -d $(PLUGIN_DIR_PURPLE) $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/{16,22,48}
	install $(LIBNAME) $(PLUGIN_DIR_PURPLE)/$(LIBNAME)
	install -m 0644 img/slack16.png $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/16/slack.png
	install -m 0644 img/slack22.png $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/22/slack.png
	install -m 0644 img/slack48.png $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/48/slack.png

install-user: $(LIBNAME)
	install -d $(HOME)/.purple/plugins
	install $(LIBNAME) $(HOME)/.purple/plugins/$(LIBNAME)

.PHONY: uninstall
uninstall: $(LIBNAME)
	rm $(PLUGIN_DIR_PURPLE)/$(LIBNAME)
	rm $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/16/slack.png
	rm $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/22/slack.png
	rm $(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/48/slack.png

.PHONY: clean
clean:
	rm -f *.o $(LIBNAME) Makefile.dep

.PHONY: modversion
modversion:
	pkg-config --modversion $(PKGS)

Makefile.dep: $(C_SRCS)
	$(CC) -MM $(CFLAGS) $^ > Makefile.dep

include Makefile.dep
