CXXFLAGS = -Wall -O0 -g

COMPILER = g++

CXXFLAGS += -I../include -L..

ARCH = $(shell uname -m)

TARGETS = client server

all: $(TARGETS)

cusp.o:	../include/cusp.cpp ../include/cusp.h ../include/libcusp.h
	g++ -Wall -O2 -o $@ -c $<

client: client.o ../libcusp.a cusp.o
	$(COMPILER) $(CXXFLAGS) client.o cusp.o -o client -lcusp -lgmp -lm

server: server.o ../libcusp.a cusp.o
	$(COMPILER) $(CXXFLAGS) server.o cusp.o -o server -lcusp -lgmp -lm

clean:
	rm -f *.o $(TARGETS)

%.o: %.cpp
	$(COMPILER) $(CXXFLAGS) -c $< -o $@
