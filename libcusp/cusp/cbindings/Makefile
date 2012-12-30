MLTON=mlton

all:	libcusp.a

clean:
	rm -f libcusp.a libcusp.so include/libcusp.h .*.d
	rm -rf html latex

%.a:	%.mlb .%.d
	@echo "Building library: $<"
	$(MLTON) -export-header include/$*.h -format archive $<

.%.d:	%.mlb
	@echo "Building makefile for library:  $<"
	@echo "$@ $*: " `$(MLTON) -stop f $< | grep -v "[ :]\|^/"` > $@

	@echo "Including makefile for library: $<"
sinclude $(patsubst %.mlb, .%.d, $(wildcard *.mlb))
