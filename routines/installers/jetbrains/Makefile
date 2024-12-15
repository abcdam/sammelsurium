# makefile to setup/remove jetbrain's IDEs
ifneq ($(filter $(LANG),py ts rs),$(LANG))
    $(error USAGE: 'make [clean] LANG={py,ts,rs}')
endif

USERLIB := $(shell realpath $(HOME)/lib)
USERBIN := $(shell realpath $(HOME)/bin)
DLDIR   := $(shell realpath $(HOME)/Downloads)

VERSION_FILE    := $(LANG).VERSION
include $(VERSION_FILE)

URL_BASE        := https://download.jetbrains.com
ARCHIVE_NAME    := $(ARCHIVE_LABEL)-$(VERSION).tar.gz
URI_FULL        := $(URL_BASE)/$(TOOL_ID)/$(ARCHIVE_NAME)

PRODUCT_LIB := $(USERLIB)/$(ARCHIVE_LABEL)
LAUNCHER    := $(PRODUCT_LIB)/bin/$(BIN)
SYMLINK     := $(USERBIN)/$(SHORT_NAME)

.PHONY: all clean

all: .setup
	$(info Finished. '$(LAUNCHER)' (version: '$(VERSION)') can be started with '$(SHORT_NAME)' command)

.download_archive:
	$(info [STEP 1/4] Downloading compressed tarball...)
	curl -s --output-dir $(DLDIR) -LO $(URI_FULL)
	@echo

.extract_archive: .download_archive
	$(info [STEP 2/4] Extracting tarball to local lib dir...)
	mkdir -p $(PRODUCT_LIB)
	tar -xzf $(DLDIR)/$(ARCHIVE_NAME) --strip-components=1 -C $(PRODUCT_LIB)
	@echo

.delete_archive: .extract_archive
	$(info [STEP 3/4] Deleting tarball...)
	rm -f $(DLDIR)/$(ARCHIVE_NAME)
	@echo

.setup: .delete_archive
	$(info [STEP 4/4] Setting permission and symlink of binary...)
	chmod +x $(LAUNCHER)
	ln -sf $(LAUNCHER) $(SYMLINK)
	@echo

clean:
	$(info Deleting files produced during installation..)
	rm -rf $(PRODUCT_LIB) $(SYMLINK) $(DLDIR)/$(ARCHIVE_NAME)
	@echo "Done."