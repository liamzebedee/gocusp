# TODO Cross platform integration https://github.com/davecheney/golang-crosscompile
make=make
swig=swig

all: preroutine generatebindings compile

clean:
	cd libcusp/cusp/cbindings; $(make) clean;
	cd cusp; sudo rm cusp_gc.c cusp.go cusp.a cusp_wrap.cxx;

preroutine:
	@echo "Compiling libcusp..."
	cd libcusp/cusp/cbindings; $(make)
	
generatebindings:
	@echo "Generating bindings..."
	cd cusp; \
	$(swig) -c++ -Wall -includeall -lstd_string.i -lstdint.i -go cusp.i

compile:
	@echo "Compiling bindings..."
	cd cusp; \
	gcc -x c++ -c -fPIC cusp_wrap.cxx; \
	gcc -shared cusp_wrap.o -o cusp_wrap.so; \
	rm cusp_wrap.o; \
	go tool 6g cusp.go; \
	go tool 6c -I ${GOROOT}/pkg/${GOOS}_${GOARCH} -D_64BIT cusp_gc.c; \
	go tool pack grc cusp.a ../libcusp/cusp/cbindings/libcusp.so cusp_wrap.so cusp.6 cusp_gc.6; \
	rm cusp.6 cusp_gc.6 cusp_wrap.so; 
	@echo "Installing..."
	sudo mkdir -p ${GOROOT}/pkg/${GOOS}_${GOARCH}/github.com/liamzebedee/gocusp/
	sudo cp -f cusp/cusp.a ${GOROOT}/pkg/${GOOS}_${GOARCH}/github.com/liamzebedee/gocusp/cusp.a
