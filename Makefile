ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

BINARY=multilog_exporter
VERSION=1.0.2
BUILD=`git rev-parse HEAD`
PLATFORMS=darwin linux windows
ARCHITECTURES=386 amd64

# Setup linker flags option for build that interoperate with variable names in src code
LDFLAGS=-ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}"

all: build test integration-test

test:
	go test

integration-test:
	./test.sh

build:
	go build ${LDFLAGS} -o bin/${BINARY}

.PHONY: build_all
build_all:
	$(foreach GOOS, $(PLATFORMS),\
	$(foreach GOARCH, $(ARCHITECTURES), $(shell export GOOS=$(GOOS); export GOARCH=$(GOARCH); go build $(LDFLAGS) -v -o bin/$(BINARY)-$(GOOS)-$(GOARCH))))

.PHONY: release
release:
	mkdir -p release/multilog_exporter_$(VERSION)
	docker build -t multilog_exporter_build -f Dockerfile.build .
	docker create --name multilog_exporter_container multilog_exporter_build && \
	docker cp multilog_exporter_container:/usr/local/bin/ release/multilog_exporter_$(VERSION); \
	docker rm multilog_exporter_container
	cd release/ && tar czvf multilog_exporter_$(VERSION).tar.gz multilog_exporter_$(VERSION) && rm -rf multilog_exporter_$(VERSION)
