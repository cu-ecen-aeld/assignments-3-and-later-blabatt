BUILD := ../build
DEST ?= ${BUILD}

default writer: writer.c
	$(CROSS_COMPILE)gcc -g -Wall -c -o $(BUILD)/writer.o writer.c

install:
	mkdir -p $(DEST)
	cp $(BUILD)/writer.o $(DEST)/writer
	cp writer.sh $(DEST)/
	chmod 744 $(DEST)/writer
	chmod 744 $(DEST)/writer.sh

clean:
	rm $(BUILD)/writer.o

