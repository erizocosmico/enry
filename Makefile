# Package configuration
PROJECT = enry
COMMANDS = cli/enry

# Including ci Makefile
MAKEFILE = Makefile.main
CI_REPOSITORY = https://github.com/src-d/ci.git
CI_FOLDER = .ci

# If you need to build more than one dockerfile, you can do so like this:
# DOCKERFILES = Dockerfile_filename1:repositoryname1 Dockerfile_filename2:repositoryname2 ...

$(MAKEFILE):
	@git clone --quiet $(CI_REPOSITORY) $(CI_FOLDER); \
	cp $(CI_FOLDER)/$(MAKEFILE) .;

-include $(MAKEFILE)

LINGUIST_PATH = .linguist

# build CLI
LOCAL_TAG := $(shell git describe --tags --abbrev=0)
LOCAL_COMMIT := $(shell git rev-parse --short HEAD)
LOCAL_BUILD := $(shell date +"%m-%d-%Y_%H_%M_%S")
LOCAL_LDFLAGS = -s -X main.version=$(LOCAL_TAG) -X main.build=$(LOCAL_BUILD) -X main.commit=$(LOCAL_COMMIT)

# shared objects
RESOURCES_DIR=./.shared
LINUX_DIR=$(RESOURCES_DIR)/linux-x86-64
LINUX_SHARED_LIB=$(LINUX_DIR)/libenry.so
DARWIN_DIR=$(RESOURCES_DIR)/darwin
DARWIN_SHARED_LIB=$(DARWIN_DIR)/libenry.dylib
HEADER_FILE=libenry.h
NATIVE_LIB=./shared/enry.go

$(LINGUIST_PATH):
	git clone https://github.com/github/linguist.git $@

clean-linguist:
	rm -rf $(LINGUIST_PATH)

clean-shared:
	rm -rf $(RESOURCES_DIR)

clean: clean-linguist clean-shared

code-generate: $(LINGUIST_PATH)
	mkdir -p data
	go run internal/code-generator/main.go

benchmarks: $(LINGUIST_PATH)
	go test -run=NONE -bench=. && benchmarks/linguist-total.sh

benchmarks-samples: $(LINGUIST_PATH)
	go test -run=NONE -bench=. -benchtime=5us && benchmarks/linguist-samples.rb

benchmarks-slow: $(LINGUST_PATH)
	mkdir -p benchmarks/output && go test -run=NONE -bench=. -slow -benchtime=100ms -timeout=100h >benchmarks/output/enry_samples.bench && \
	benchmarks/linguist-samples.rb 5 >benchmarks/output/linguist_samples.bench

build-cli:
	go build -o enry -ldflags "$(LOCAL_LDFLAGS)" cli/enry/main.go

linux-shared: $(LINUX_SHARED_LIB)

darwin-shared: $(DARWIN_SHARED_LIB)

$(DARWIN_SHARED_LIB):
	mkdir -p $(DARWIN_DIR) && \
	CC="o64-clang" CXX="o64-clang++" CGO_ENABLED=1 GOOS=darwin go build -buildmode=c-shared -o $(DARWIN_SHARED_LIB) $(NATIVE_LIB) && \
	mv $(DARWIN_DIR)/$(HEADER_FILE) $(RESOURCES_DIR)/$(HEADER_FILE)

$(LINUX_SHARED_LIB):
	mkdir -p $(LINUX_DIR) && \
	GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o $(LINUX_SHARED_LIB) $(NATIVE_LIB) && \
	mv $(LINUX_DIR)/$(HEADER_FILE) $(RESOURCES_DIR)/$(HEADER_FILE)
