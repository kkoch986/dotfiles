DOTDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
HOME   := $(or $(HOME),$(shell echo ~))

STOW  := $(shell command -v stow 2>/dev/null)
PACKAGES := home

.PHONY: all install stow-dry stow stow-home clean backup help

all: install

install: stow

# --- Stow (default) ---

stow-dry:
ifndef STOW
	$(error "GNU Stow not found. Install with: sudo pacman -S stow")
endif
	@echo "=== DRY RUN ==="
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "--- $$pkg ---"; \
		stow --verbose --no --target=$(HOME) $$pkg; \
	done

stow:
ifndef STOW
	$(error "GNU Stow not found. Install with: sudo pacman -S stow")
endif
	@echo "Deploying dotfiles with stow..."
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  stow $$pkg"; \
		stow --restow --target=$(HOME) $$pkg; \
	done
	@echo "Done. Run 'make backup' first if you want to save existing files."

# Individual stow packages
stow-home:
	cd $(DOTDIR) && stow --restow --target=$(HOME) home

# --- Backup existing dotfiles ---

BACKUP_DIR := $(DOTDIR)backup-$(shell date +%Y%m%d-%H%M%S)

backup:
	@echo "Backing up existing dotfiles to $(BACKUP_DIR)..."
	@mkdir -p $(BACKUP_DIR)
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		cd $$pkg && \
		find . -type f -o -type l | while IFS= read -r f; do \
			src="$(HOME)/$$f"; \
			if [ -e "$$src" ] && [ ! -L "$$src" ]; then \
				dst="$(BACKUP_DIR)/$$f"; \
				mkdir -p "$$(dirname "$$dst")"; \
				cp -a "$$src" "$$dst"; \
				echo "  backed up: $$src"; \
			fi; \
		done; \
		cd $(DOTDIR); \
	done
	@echo "Backup saved to $(BACKUP_DIR)"

# --- Clean -- remove symlinks managed by stow ---

clean:
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  unstowing $$pkg"; \
		stow --delete --target=$(HOME) $$pkg 2>/dev/null || true; \
	done
	@echo "Symlinks removed."

# --- Help ---

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all / install   Deploy all dotfiles with stow (default)"
	@echo "  stow-dry        Dry run -- show what stow would do"
	@echo "  stow-home       Deploy only home configs (shell, editors, etc.)"
	@echo "  backup          Backup existing non-symlinked dotfiles before deploying"
	@echo "  clean           Remove all symlinks managed by stow"
	@echo "  help            Show this message"
	@echo ""
	@echo "Prerequisites:"
	@echo "  Install stow: sudo pacman -S stow"
	@echo "  Then: make backup && make"
