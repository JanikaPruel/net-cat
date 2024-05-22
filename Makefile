.PHONY: all build run clean test

all: build

build:
	go build -o bin/tcp-chat ./cmd/tcp-chat

run: build
	./bin/tcp-chat

clean:
	rm -rf bin

test:
	go test ./...
