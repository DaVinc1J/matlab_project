CC = clang
CFLAGS = -I/opt/homebrew/include
LDFLAGS = -L/opt/homebrew/lib -lglfw -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo

all: main

glfw: main.c
	$(CC) glfw.c -o glfw $(CFLAGS) $(LDFLAGS)

clean:
	rm -f glfw
