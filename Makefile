default: executable

.PHONY: build
build:
	@swift build

.PHONY: test
test:
	@swift test

.PHONY: executable
executable:
	swift run -c release swift-public-rewriter --help
