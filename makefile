ODIN = odin
OUT = lvo
WIN_OUT = $(OUT).exe
SRC = src/
SRC_FILES = $(SRC)/*
VERSION = x86_64-ALPHA-0.0.1

all: $(OUT)
windows: $(WIN_OUT)

winpkg: $(WIN_OUT)
	zip -r lvo-windows-$(VERSION).zip lvo.exe assets
unixpkg: $(OUT)
	zip -r lvo-linux-$(VERSION).zip lvo assets

$(OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(OUT)

$(WIN_OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(WIN_OUT) -target:windows_amd64
	x86_64-w64-mingw32-gcc $(OUT).obj windows/chkstk.S -Lwindows -lglfw3 -lucrt -fstack-protector -luser32 -lgdi32 -static -o $(WIN_OUT)
	rm $(OUT).obj

run: $(OUT)
	./$(OUT)

clean: 
	rm $(OUT).obj $(OUT) $(WIN_OUT)

lines: 
	wc src/*.odin assets/shaders/*