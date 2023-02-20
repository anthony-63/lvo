ODIN = odin
OUT = lvo.exe
SRC = src/
SRC_FILES = $(SRC)/*
VERSION = x86_64-ALPHA-0.0.4
FIX =
all: $(OUT)

$(OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(OUT)

run: $(OUT)
	./$(OUT)

clean: 
	rm $(OUT).obj $(OUT) *.rar

lines: 
	for %f in (src/*.odin) do find /v /c "" "%f"

