SWIFT_LINUX_TOOLCHAIN_DOWNLOAD_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-DEVELOPMENT-SNAPSHOT-2023-05-12-a/swift-wasm-DEVELOPMENT-SNAPSHOT-2023-05-12-a-ubuntu20.04_aarch64.tar.gz"
WABT_LINUX_DOWNLOAD_URL="https://github.com/WebAssembly/wabt/releases/download/1.0.33/wabt-1.0.33-ubuntu.tar.gz"

ifeq  ($(shell uname),Darwin)
WABT_DOWNLOAD_URL="https://github.com/WebAssembly/wabt/releases/download/1.0.33/wabt-1.0.33-macos-12.tar.gz"
SWIFT_TOOLCHAIN_DOWNLOAD_URL="https://github.com/swiftwasm/swift/releases/download/swift-wasm-5.9-SNAPSHOT-2023-07-11-a/swift-wasm-5.9-SNAPSHOT-2023-07-11-a-macos_arm64.pkg"
else ifeq ($(shell uname),Linux)
WABT_DOWNLOAD_URL=$(WABT_LINUX_DOWNLOAD_URL)
SWIFT_TOOLCHAIN_DOWNLOAD_URL=$(SWIFT_LINUX_TOOLCHAIN_DOWNLOAD_URL)
endif

LIBATOMIC_DOWNLOAD_URL="http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/aarch64/RPMS.classic/libatomic1-13.1.1-alt1.aarch64.rpm"
LIBSTDCXX_DOWNLOAD_URL="http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/aarch64/RPMS.classic/libstdc%2B%2B6-13.1.1-alt1.aarch64.rpm"

prebuilt/wabt:
	mkdir -p $@ && cd $@ && \
		curl -L $(WABT_DOWNLOAD_URL) | tar xz --strip-components 1
prebuilt/swift:
ifeq ($(shell uname),Linux)
	mkdir -p $@ && cd $@ && \
		curl -L $(SWIFT_TOOLCHAIN_DOWNLOAD_URL) | tar xz --strip-components 1
else
	mkdir -p $@ && cd $@ && \
		curl -L $(SWIFT_TOOLCHAIN_DOWNLOAD_URL) -o ./swifttoolchain.pkg && sudo installer -pkg ./swifttoolchain.pkg -target / && rm ./swifttoolchain.pkg
endif
prebuilt/linux/wabt: prebuilt/wabt
ifeq ($(shell uname),Linux)
	mkdir -p prebuilt/linux
	cp -a prebuilt/wabt prebuilt/linux/wabt
else
	mkdir -p $@ && cd $@ && \
		curl -L $(WABT_LINUX_DOWNLOAD_URL) | tar xz --strip-components 1
endif
	./utils/remove-wabt-extra-files.sh ./prebuilt/linux/wabt

prebuilt/linux/swift: prebuilt/swift
ifeq ($(shell uname),Linux)
	mkdir -p prebuilt/linux
	cp -a prebuilt/swift prebuilt/linux/swift
else
	mkdir -p $@ && cd $@ && \
		curl -L $(SWIFT_LINUX_TOOLCHAIN_DOWNLOAD_URL) | tar xz --strip-components 1
endif
	./utils/remove-swift-extra-files.sh ./prebuilt/linux/swift
prebuilt/libatomic.so.1:
	./utils/download-libatomic.sh $(LIBATOMIC_DOWNLOAD_URL)
prebuilt/libstdc++.so.6:
	./utils/download-libstdc++.sh $(LIBSTDCXX_DOWNLOAD_URL)

FirebaseFunction/functions/prebuilt: prebuilt/linux/swift prebuilt/linux/wabt
	mkdir -p $@
	cp -af $^ $@
FirebaseFunction/functions/service.js: service.js
	cp $< $@
FirebaseFunction/functions/extralib: prebuilt/libatomic.so.1 prebuilt/libstdc++.so.6
	mkdir -p $@
	cp prebuilt/libatomic.so.1 $@/libatomic.so.1
	cp prebuilt/libstdc++.so.6 $@/libstdc++.so.6

.PHONY: deploy
deploy: FirebaseFunction/functions/service.js FirebaseFunction/functions/prebuilt FirebaseFunction/functions/extralib
