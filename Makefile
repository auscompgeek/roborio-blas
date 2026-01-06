
VERSION = 2.0

BINRELEASE = https://github.com/flame/blis/archive/refs/tags/$(VERSION).tar.gz
LIBGZIP = $(abspath $(notdir ${BINRELEASE}))
SRCDIR = blis-$(VERSION)

CROSS_COMPILE=arm-frc2025-linux-gnueabi-
AS=$(CROSS_COMPILE)as
FC=$(CROSS_COMPILE)gfortran
CC=$(CROSS_COMPILE)gcc
CXX=$(CROSS_COMPILE)g++
AR=$(CROSS_COMPILE)ar
RANLIB=$(CROSS_COMPILE)ranlib
STRIP=$(CROSS_COMPILE)strip

PYTHON=python3.14

MAKE_OPTIONS=DESTDIR=../prefix

all: package

${LIBGZIP}:
	wget ${BINRELEASE}

${SRCDIR}: ${LIBGZIP}
	tar -xf ${LIBGZIP}
	cd $(SRCDIR) && patch -p1 < ../machine-flags.patch

.PHONY: compile
compile: ${SRCDIR}
	rm -rf prefix
	cd ${SRCDIR} && AS=$(AS) CC=$(CC) CXX=$(CXX) FC=$(FC) AR=$(AR) RANLIB=$(RANLIB) PYTHON=$(PYTHON) ./configure --prefix=/usr/local cortexa9
	cd ${SRCDIR} && make $(MAKE_OPTIONS)
	cd ${SRCDIR} && make $(MAKE_OPTIONS) install

.PHONY: package
package: compile
	rm -rf data devdata

	# create release package
	mkdir -p data/usr/local/lib
	cp -L prefix/usr/local/lib/libblis.so.4 data/usr/local/lib/
	roborio-gen-whl data.py data -o dist --strip $(STRIP)
	
	# create development package
	mkdir -p devdata/usr/local/lib devdata/usr/local/share
	cp -r prefix/usr/local/include devdata/usr/local/include
	cp -r prefix/usr/local/share/pkgconfig devdata/usr/local/share/pkgconfig
	cp -L prefix/usr/local/lib/libblis.so devdata/usr/local/lib/
	cp -L prefix/usr/local/lib/libblis.a devdata/usr/local/lib/
	roborio-gen-whl --dev data.py devdata -o dist
