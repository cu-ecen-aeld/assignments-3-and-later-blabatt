# CROSS_COMPILE ?= aarch64-none-linux-gnu-gcc # shouldn't need this from buildroot if using $(CC)
BUILD ?= .
DEST ?= ${BUILD}
CC ?= $(CROSS_COMPILE)gcc
STEM = aesdsocket

default socket: $(STEM).c
	$(CC) $(CFLAGS) $(INCLUDES) -g -Wall -c -o $(BUILD)/$(STEM).o $(STEM).c
	$(CC) $(CFLAGS) $(INCLUDES) -g -Wall -I/ $(BUILD)/$(STEM).o -o $(BUILD)/$(STEM)
	# $(CC) -g -Wall -c -o $(BUILD)/$(STEM).o $(STEM).c

all: default

install:
	mkdir -p $(DEST)
	cp $(BUILD)/$(STEM).o $(DEST)/$(STEM)
	cp $(STEM).sh $(DEST)/
	cp finder.sh $(DEST)/
	chmod 744 $(DEST)/$(STEM)
	chmod 744 $(DEST)/$(STEM).sh
	chmod 744 $(DEST)/finder.sh

clean:
	-rm $(BUILD)/$(STEM).o
	-rm $(BUILD)/$(STEM)

run: 
	./aesdsocket
