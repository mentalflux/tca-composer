PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS 17.5,iPhone \d\+ Pro [^M])

test-swift:
	swift test --parallel

test-examples:
	for scheme in SyncUps Todos VoiceMemos; do \
		xcodebuild test \
			-skipMacroValidation \
			-scheme "$$scheme" \
      -destination platform="$(PLATFORM_IOS)" || exit 1; \
		done

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
