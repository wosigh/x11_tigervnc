# Packages up TigerVNCViewer
NAME = tigervnc
VERSION = 0.2.6
PKG = uk.co.eridani.tigervnc

SRC_GIT = git://git.webos-internals.org/x11/tigervnc.git

include ../../../support/download.mk
include ../../../support/staging.mk
include ../../../support/cross-compile.mk

stage-local:: build


.PHONY: unpack
unpack: build/.unpacked-${VERSION}

build/.unpacked-${VERSION}: ${DL_DIR}/${NAME}-${VERSION}.tar.gz
	rm -f $@
	mkdir -p build/src
	tar -C build/src -x -v -f $<
	touch $@

build: build/${ARCH}.built-${VERSION}

src-update: build/.unpacked-${VERSION}
	( cd build/src && git checkout master && git pull )

build/%.built-${VERSION}: build/.unpacked-${VERSION}
	rm -f $@
	( rm -rf build/$* )
	( mkdir -p build/$* )
	( cp build/src/index.html build/$* )
	( cp build/src/sources.json build/$* )
	( cp build/src/xecutah.sh build/$* )
	( cp build/src/icon.png build/$* )
	( cp build/src/appinfo.json build/$* )
	( cp build/src/package.properties build/$* )
	( mkdir -p build/$*/bin )
	( cp build/src/armv7/bin/dwm build/$*/bin/ )
	( cp build/src/armv7/bin/vncviewer build/$*/bin/ )
	( mkdir -p build/$*/app/assistants build/$*/app/views/change-log )
	( cp build/src/app/stylesheet.css build/$*/app/ )
	( cp build/src/app/assistants/change-log-assistant.js build/$*/app/assistants/ )
	( cp build/src/app/assistants/app-assistant.js build/$*/app/assistants/ )
	( cp build/src/app/views/change-log/change-log-scene.html build/$*/app/views/change-log/ )
	( cp build/src/app/views/change-log/row.html build/$*/app/views/change-log/ )
	( mkdir -p build/$*/control )
	( cp build/src/control/postinst build/$*/control/ )
	( cp build/src/control/prerm build/$*/control/ )
	( mkdir -p build/$*/upstart )
	( cp build/src/upstart/uk.co.eridani.tigervnc build/$*/upstart )
	touch $@

# TODO: Add armv6 support
package-commit:
	if [ -d git ]; then \
		(cd git && git checkout . && git pull); \
	else \
		git clone "${SRC_GIT_COMMIT}" git; \
	fi
	cd git && rm -rf armv7
	mkdir -p git/armv7
	tar -C build/armv7 -cf - . | tar -C git/armv7 -xf -
	rm -f git/armv7/* || true # don't delete the directories
	#mkdir -p git/armv6
	#tar -C build/armv6 -cf - . | tar -C git/armv6 -xf -
	#rm -f git/armv6/* || true # don't delete the directories
	( cd git && git add . && git commit -am "(Automatic commit)" )

package:
	mkdir -p build/ipk
	rm -rf build/ipk/*.ipk
	palm-package -o build/ipk build/${ARCH}
	#Add postinst/prerm, based on hello.git's Makefile.
	#cd build/src && ar q ../ipk/${PKG}_${VERSION}_all.ipk pmPostInstall.script
	#cd build/src && ar q ../ipk/${PKG}_${VERSION}_all.ipk pmPreRemove.script
	# I really, really do not like this, but this massages control.tar.gz to look like my working hand-rolled one.
	cp build/src/control/postinst build/src/control/prerm build/ipk/ && chmod 755 build/ipk/postinst build/ipk/prerm
	cd build/ipk && ar x ${PKG}_${VERSION}_all.ipk control.tar.gz && tar -xzf control.tar.gz && mv control control.in
	cd build/ipk && sed 's/This is a webOS application/TigerVNCViewer for webOS/' control.in | sed 's/ all/ armv7/' | sed 's:N/A <nobody@example.com>:Eridani Star System:' > control
	cd build/ipk && tar --owner=root --group=wheel -czvf control.tar.gz ./control ./postinst ./prerm
	cd build/ipk && ar r ${PKG}_${VERSION}_all.ipk control.tar.gz && rm -f control control.in control.tar.gz postinst prerm
	cd build/ipk && mv ${PKG}_${VERSION}_all.ipk ${PKG}_${VERSION}_armv7.ipk 

install:
	-palm-install -r uk.co.eridani.tigervnc
	palm-install build/ipk/*.ipk

test: stage package install

clobber::
	rm -rf build


