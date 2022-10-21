ODIN = odin
OUT = lvo
SRC = src/
SRC_FILES = $(SRC)/*
FLAGS = -lld
all: $(OUT)

$(OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(OUT) $(FLAGS)

run: $(OUT)
	./$(OUT)