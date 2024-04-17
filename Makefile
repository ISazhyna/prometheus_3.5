ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := windows
	detected_arch := amd64
else
    detected_OS := $(shell uname | tr '[:upper:]' '[:lower:]' 2> /dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
	detected_arch := $(shell dpkg --print-architecture 2>/dev/null || amd64)
endif

#colors:
B = \033[1;94m#   BLUE
G = \033[1;92m#   GREEN
Y = \033[1;93m#   YELLOW
R = \033[1;31m#   RED
M = \033[1;95m#   MAGENTA
K = \033[K#       ERASE END OF LINE
D = \033[0m#      DEFAULT
A = \007#         BEEP

APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=umanetsvitaliy
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

build:
	@printf "$GDetected OS/ARCH: $R$(detected_OS)/$(detected_arch)$D\n"
	CGO_ENABLED=0 GOOS=$(detected_OS) GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}

linux:
	@printf "$GTarget OS/ARCH: $Rlinux/$(detected_arch)$D\n"
	CGO_ENABLED=0 GOOS=linux GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=linux -t ${REGISTRY}/${APP}:${VERSION}-linux-$(detected_arch) .

windows:
	@printf "$GTarget OS/ARCH: $Rwindows/$(detected_arch)$D\n"
	CGO_ENABLED=0 GOOS=windows GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=windows -t ${REGISTRY}/${APP}:${VERSION}-windows-$(detected_arch) .

darwin:
	@printf "$GTarget OS/ARCH: $Rdarwin/$(detected_arch)$D\n"
	CGO_ENABLED=0 GOOS=darwin GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=darwin -t ${REGISTRY}/${APP}:${VERSION}-darwin-$(detected_arch) .

arm:
	@printf "$GTarget OS/ARCH: $R$(detected_OS)/arm$D\n"
	CGO_ENABLED=0 GOOS=$(detected_OS) GOARCH=arm go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=arm -t ${REGISTRY}/${APP}:${VERSION}-$(detected_OS)-arm .

image: build
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-$(detected_arch)

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-$(detected_arch)

clean:
	@rm -rf kbot; \
	IMG1=$$(docker images -q | head -n 1); \
	if [ -n "$${IMG1}" ]; then  docker rmi -f $${IMG1}; else printf "$RImage not found$D\n"; fi