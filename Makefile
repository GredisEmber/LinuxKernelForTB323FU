.PHONY: build prepare verify install release clean

build:
	./scripts/build.sh

prepare:
	./scripts/build.sh --prepare-only

verify:
	./scripts/verify.sh

install:
	./scripts/install-on-device.sh

release:
	./scripts/publish-release.sh

clean:
	rm -rf work dist
