APP_NAME = MarstekWidget
APP_BUNDLE = $(APP_NAME).app

.PHONY: build app zip release clean

build:
	swift build -c release

app: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp .build/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/

zip: app
	rm -f $(APP_NAME).zip
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) $(APP_NAME).zip

# Build for specific architecture
build-arm64:
	swift build -c release --arch arm64

build-x86_64:
	swift build -c release --arch x86_64

# Create .app for specific architecture
app-arm64: build-arm64
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp .build/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/

app-x86_64: build-x86_64
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp .build/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/

# Create zips for each architecture
zip-arm64: app-arm64
	rm -f $(APP_NAME)-arm64.zip
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) $(APP_NAME)-arm64.zip

zip-x86_64: app-x86_64
	rm -f $(APP_NAME)-x86_64.zip
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) $(APP_NAME)-x86_64.zip

# Build both architectures
release: zip-arm64 zip-x86_64
	@echo "Release artifacts:"
	@ls -lh $(APP_NAME)-arm64.zip $(APP_NAME)-x86_64.zip

clean:
	rm -rf $(APP_BUNDLE) $(APP_NAME)*.zip
	swift package clean
