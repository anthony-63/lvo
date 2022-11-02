ODIN = odin
OUT = lvo
WIN_OUT = $(OUT).exe
SRC = src/
SRC_FILES = $(SRC)/*
VERSION = x86_64-ALPHA-0.0.4
FIX =
all: $(OUT)
windows: $(WIN_OUT)

winpkg: $(WIN_OUT)
	zip -r lvo-windows-$(VERSION)$(FIX).zip lvo.exe assets
unixpkg: $(OUT)
	zip -r lvo-linux-$(VERSION)$(FIX).zip lvo assets

$(OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(OUT)

$(WIN_OUT): $(SRC_FILES)
	$(ODIN) build $(SRC) -out:$(WIN_OUT) -lld -target:windows_amd64
	x86_64-w64-mingw32-gcc $(OUT).obj windows/chkstk.obj -Lwindows -lglfw3 -lucrt -luser32 -lgdi32 -lgcc -static-libgcc -static -o $(WIN_OUT)
	rm $(OUT).obj

run: $(OUT)
	./$(OUT)

clean: 
	rm $(OUT).obj $(OUT) $(WIN_OUT) *.zip

lines: 
	wc src/*.odin assets/shaders/*