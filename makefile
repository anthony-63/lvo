ODIN = odin
OUT = lvo
SRC = src/
SRC_FILES = $(SRC)/*
FLAGS = -lld -debug
all: $(OUT)

$(OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(OUT) $(FLAGS)

run: $(OUT)
	./$(OUT)

lines: 
	wc src/*.odin assets/shaders/*