# TODO Cross platform integration https://github.com/davecheney/golang-crosscompile 

make=make
swig=swig

all: preroutine generatebindings compile

clean:
	rm *.c
	rm *.cxx
	rm *.o
	rm *.so

preroutine:
	@echo "Compiling libcusp..."
	cd cusp/cbindings; $(make)
#$(make) clean; 
	
generatebindings:
	@echo "Generating bindings..."
	$(swig) -c++ -Wall -go cusp.i
	
compile:
	@echo "Compiling bindings..."
	gcc -x c++ -c -fpic cusp/cbindings/include/cusp.cpp
	gcc -x c++ -c -fpic cusp_wrap.cxx
	gcc -shared cusp.o cusp_wrap.o -o cusp.so
