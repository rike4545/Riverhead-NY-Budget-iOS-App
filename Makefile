# Local build gate for the Riverhead NY Budget App.
#
# Why this exists: every Swift error in this project so far has been found by
# GitHub Actions, on macos-latest, on a private repo — where macOS minutes bill
# at a 10x multiplier. A compile error costs ~8 minutes of billed runner time
# and a round trip. The same error costs seconds here.
#
# `make compile` is the one to run before committing. It compiles the app AND
# both test bundles without booting a simulator. That distinction matters:
# plain `xcodebuild build` compiles only the app target, and both errors that
# reached CI recently were in test files, so `build` would have missed them.
# `build-for-testing` is what catches them.
#
# Destination picking and simulator boot reuse the exact scripts CI runs, so a
# green `make check` means the same thing locally as it does in the workflow.

PROJECT   := Riverhead NY Budget App.xcodeproj
SCHEME    := Riverhead NY Budget App
UI_BUNDLE := Riverhead NY Budget AppUITests
SCRIPTS   := .github/scripts
LOGS      := build-logs

# summarise.sh writes GitHub-flavoured markdown for the CI step summary. The
# same output is reused here so local and CI report identically; plain.sed just
# drops the fences and headings so it reads as plain terminal text.
PLAIN := sed -f $(SCRIPTS)/plain.sed

.DEFAULT_GOAL := help
.PHONY: help compile check ui all clean

help:
	@echo ''
	@echo '  make compile   compile app + test bundles, no simulator   <- run before committing'
	@echo '  make check     compile + run the unit suite on a simulator'
	@echo '  make ui        run the UI suite (slow: boots and drives a simulator)'
	@echo '  make all       everything CI runs'
	@echo '  make clean     delete this project'"'"'s DerivedData and logs'
	@echo ''
	@echo '  Logs land in $(LOGS)/. Failures print the distinct error lines via'
	@echo '  the same summarise.sh that writes the CI step summary.'
	@echo ''

# The fast gate. No simulator is booted and none needs to exist: a generic
# destination is enough to type-check and compile every target in the scheme.
compile:
	@mkdir -p '$(LOGS)'
	@echo '==> compiling app + test bundles'
	@start=$$(date +%s); \
	if xcodebuild build-for-testing \
		-project '$(PROJECT)' \
		-scheme '$(SCHEME)' \
		-destination 'generic/platform=iOS Simulator' \
		CODE_SIGNING_ALLOWED=NO \
		-quiet >'$(LOGS)/compile.log' 2>&1; then \
		echo "    compiles clean in $$(( $$(date +%s) - start ))s"; \
	else \
		echo ''; \
		echo "    COMPILE FAILED after $$(( $$(date +%s) - start ))s"; \
		echo ''; \
		bash '$(SCRIPTS)/summarise.sh' '$(LOGS)/compile.log' 'Compile' | $(PLAIN); \
		echo "full log: $(LOGS)/compile.log"; \
		exit 1; \
	fi

# Unit suite. Picks and boots a simulator with the same scripts CI uses, so a
# pass here and a pass there mean the same thing.
check:
	@mkdir -p '$(LOGS)'
	@echo '==> picking a simulator'
	@udid=$$(bash '$(SCRIPTS)/pick-destination.sh' '$(PROJECT)' '$(SCHEME)') && \
	bash '$(SCRIPTS)/boot-simulator.sh' "$$udid" && \
	echo '==> building and running the unit suite' && \
	if xcodebuild test \
		-project '$(PROJECT)' \
		-scheme '$(SCHEME)' \
		-destination "id=$$udid" \
		-skip-testing:'$(UI_BUNDLE)' \
		CODE_SIGNING_ALLOWED=NO \
		>'$(LOGS)/unit.log' 2>&1; then \
		grep -aE 'Executed [0-9]+ test|Test run with [0-9]+ test' '$(LOGS)/unit.log' | sort -u | sed 's/^[[:space:]]*/    /' | tail -3; \
		echo '    unit suite passed'; \
	else \
		echo ''; \
		bash '$(SCRIPTS)/summarise.sh' '$(LOGS)/unit.log' 'Unit run' | $(PLAIN); \
		echo "full log: $(LOGS)/unit.log"; \
		exit 1; \
	fi

ui:
	@mkdir -p '$(LOGS)'
	@echo '==> picking a simulator'
	@udid=$$(bash '$(SCRIPTS)/pick-destination.sh' '$(PROJECT)' '$(SCHEME)') && \
	bash '$(SCRIPTS)/boot-simulator.sh' "$$udid" && \
	echo '==> running the UI suite (a few minutes)' && \
	if xcodebuild test \
		-project '$(PROJECT)' \
		-scheme '$(SCHEME)' \
		-destination "id=$$udid" \
		-only-testing:'$(UI_BUNDLE)' \
		-resultBundlePath '$(LOGS)/ui.xcresult' \
		CODE_SIGNING_ALLOWED=NO \
		>'$(LOGS)/ui.log' 2>&1; then \
		echo '    UI suite passed'; \
	else \
		echo ''; \
		bash '$(SCRIPTS)/summarise.sh' '$(LOGS)/ui.log' 'UI run' | $(PLAIN); \
		echo "screenshots: $(LOGS)/ui.xcresult"; \
		exit 1; \
	fi

all: check ui

clean:
	@rm -rf '$(LOGS)'
	@xcodebuild clean -project '$(PROJECT)' -scheme '$(SCHEME)' -quiet || true
	@echo 'cleaned'
