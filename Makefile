#############################################
##                                         ##
##    Copyright (C) 2019-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

TOOL_TRIPLET_PREFIX ?= i686-w64-mingw32-
CC := $(TOOL_TRIPLET_PREFIX)gcc
CXX := $(TOOL_TRIPLET_PREFIX)g++
AR := $(TOOL_TRIPLET_PREFIX)ar
WINDRES := $(TOOL_TRIPLET_PREFIX)windres
STRIP := $(TOOL_TRIPLET_PREFIX)strip
GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I.. -Iexternal/libjpeg-turbo 
ALLSRCFLAGS += $(INCFLAGS) -DGIT_TAG=\"$(GIT_TAG)\"
CFLAGS += -O3 -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DUNICODE -D_UNICODE 
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += -static -static-libgcc -shared -Wl,--add-stdcall-alias
LDLIBS +=

%.o: %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) -o $@ $<

%.o: %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

LIBJPEG_TURBO_SOURCES += external/libjpeg-turbo/build/libturbojpeg.a
SOURCES := extractor.c spi00in.c ifjpeg-turbo.rc $(LIBJPEG_TURBO_SOURCES)
OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.rc=.o)

BINARY ?= ifjpeg-turbo_unstripped.spi
BINARY_STRIPPED ?= ifjpeg-turbo.spi
ARCHIVE ?= ifjpeg-turbo.$(GIT_TAG).7z

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean:
	rm -f $(OBJECTS) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE)
	rm -rf external/libjpeg-turbo/build

external/libjpeg-turbo/build/libturbojpeg.a:
	mkdir -p external/libjpeg-turbo/build && cd external/libjpeg-turbo/build && cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=../../../mingw32.cmake -DCMAKE_BUILD_TYPE=Release .. && ninja

$(ARCHIVE): $(BINARY_STRIPPED)
	rm -f $(ARCHIVE)
	7z a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(OBJECTS) 
	@printf '\t%s %s\n' LNK $@
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)
