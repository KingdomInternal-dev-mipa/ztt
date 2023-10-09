# Variables
ARCH ?= x86_64-unknown-linux-gnu# default to x86_64-unknown-linux-gnu if not set
RUST_TARGET_DIR = target/$(ARCH)/rel-opt
ZIG_TARGET_DIR = zig-out
RUST_LIB_NAME = ztt
ZIG_EXEC_NAME = ztt
ZIG_BUILD_FILE = build.zig
BUILD_DIR = build

all: rust_lib zig_build run ## Default target

rust_lib: ## Build Rust library
	@mkdir -p $(BUILD_DIR)
	@cargo build --profile rel-opt
	@echo "Rust library built successfully."

zig_build: rust_lib ## Build Zig binary
	@cp -r $(RUST_TARGET_DIR)/lib$(RUST_LIB_NAME).so $(BUILD_DIR)
	@zig build
	@echo "Zig binary built successfully."

run: zig_build ## Run Zig executable
	@./$(ZIG_TARGET_DIR)/bin/$(ZIG_EXEC_NAME)
	@echo "Zig project run successfully."

f:  ## Format Zig
	clear
	@zig fmt src/main.zig

a: ## Add deps
	clear
	@./scripts/add.sh $(filter-out $@,$(MAKECMDGOALS))
	@zig_hash=$$(zig build 2>&1 | grep -oP 'expected \.hash = "\K[^"]+'); \
	if [ -z "$$zig_hash" ]; then \
		printf "\033[0;31mFailed to capture library hash. Remove the library.\033[0m\n"; \
		./scripts/remove.sh ; \
	else \
		./scripts/hash.sh $$zig_hash; \
	fi

e: ## Expel deps
	clear
	@./scripts/remove.sh

t: ## Test all
	clear
	@./scripts/test.sh

# https://github.com/mvdan/sh
s: ## Shell format
	clear
	@shfmt -p -w scripts

c:  ## Clean
	@clear
	@rm -rf $(RUST_TARGET_DIR) $(ZIG_TARGET_DIR) $(BUILD_DIR)/lib$(RUST_LIB_NAME).so $(INCLUDE_DIR)/$(RUST_LIB_NAME).h
	@rm -rf target $(BUILD_DIR)
	@rm -rf target $(INCLUDE_DIR)
	@rm -f Cargo.lock
	@rm -rf zig-cache
	@rm -rf zig-out
	@echo "Cleaned up successfully."

# make rel v=X.Y.Z
rel: ## Create new release
	sh scripts/release.sh v$(v)

# Help
h:
	clear
	@echo ''
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ''
