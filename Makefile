# TODO Cross platform integration https://github.com/davecheney/golang-crosscompile
make=make
swig=swig

all: libcusp gocusp compile install

clean:
	cd libcusp/cusp/cbindings; $(make) clean;
	cd cusp; sudo rm cusp_gc.c cusp.go cusp.a cusp_wrap.cxx;

libcusp:
	@echo "Compiling libcusp..."
	cd libcusp/cusp/cbindings; $(make)
	
gocusp:
	@echo "Generating bindings..."
	cd cusp; \
	$(swig) -c++ -Wall -includeall -go cusp.i

compile:
	@echo "Compiling bindings..."
	cd cusp; \
	g++ -Wall -fPIC -g -o cusp.o -c ../libcusp/cusp/cbindings/include/cusp.cpp ../libcusp/cusp/cbindings/include/cusp.h ../libcusp/cusp/cbindings/include/libcusp.h; \
	g++ -c -fPIC -lstdc++ cusp_wrap.cxx; \
	gcc -I../libcusp/cusp/cbindings/include/ -L../libcusp/cusp/cbindings/ -lcusp cusp.o cusp_wrap.o -shared -o cusp.so; \
#	rm cusp_wrap.o cusp.o; \
	go tool 6g cusp.go; \
	go tool 6c -I ${GOROOT}/pkg/${GOOS}_${GOARCH} -D_64BIT cusp_gc.c; \
	go tool pack grc cusp.a cusp.6 cusp_gc.6; \
	rm cusp.6 cusp_gc.6;
	
install:
	@echo "Installing..."
	sudo mkdir -p ${GOROOT}/pkg/${GOOS}_${GOARCH}/github.com/liamzebedee/gocusp/
	sudo rm ${GOROOT}/pkg/${GOOS}_${GOARCH}/github.com/liamzebedee/gocusp/cusp.a
	sudo cp -f cusp/cusp.a ${GOROOT}/pkg/${GOOS}_${GOARCH}/github.com/liamzebedee/gocusp/cusp.a
	sudo rm /usr/local/lib/cusp.so; sudo cp -f cusp/cusp.so /usr/local/lib/
