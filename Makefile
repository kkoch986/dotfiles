DOTDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
HOME   := $(or $(HOME),$(shell echo ~))

STOW  := $(shell command -v stow 2>/dev/null)
PACKAGES := home

# Config paths and the binary(s) they need (comma-separated alternatives)
# Format: path:binary[,binary,...]
TOOLS := \
  home/.tmux.conf:tmux \
  home/.config/nvim:nvim \
  home/.config/hypr:Hyprland \
  home/.config/kitty:kitty \
  home/.config/foot:foot \
  home/.config/fish:fish \
  home/.config/starship.toml:starship \
  home/.config/wlogout:wlogout \
  home/.config/fuzzel:fuzzel \
  home/.config/mpv:mpv \
  home/.zshrc:zsh \
  home/.bashrc:bash

.PHONY: all install check-deps stow stow-dry stow-home backup clean help

all: install

# Check each config file exists and its binary is available
check-deps:
	@echo "=== Checking required tools ==="; \
	missing=""; \
	for pair in $(TOOLS); do \
		cfg="$${pair%%:*}"; \
		bins="$${pair#*:}"; \
		cfgpath="$(DOTDIR)$$cfg"; \
		if [ -e "$$cfgpath" ]; then \
			found=0; \
			for b in $$(echo "$$bins" | tr ',' ' '); do \
				if command -v "$$b" >/dev/null 2>&1; then found=1; first="$$b"; break; fi; \
			done; \
			if [ "$$found" -eq 0 ]; then \
				missing="$$missing  \342\200\242 $$cfg  \342\206\222  install: $$bins\n"; \
			else \
				printf "  \342\234\223 %-30s %s\n" "$$first" "$$cfg"; \
			fi; \
		fi; \
	done; \
	if [ -n "$$missing" ]; then \
		echo ""; \
		echo "WARNING: Configs found for missing tools:"; \
		printf "$$missing"; \
		echo ""; \
		echo "Install with: sudo pacman -S <pkg>  (Arch)"; \
		echo "Or:          brew install <pkg>   (macOS)"; \
		echo "Configs without the tool are harmless."; \
	else \
		echo "  All tools found."; \
	fi

install: check-deps
ifndef STOW
	$(error "GNU Stow not found. Install with: sudo pacman -S stow")
endif
	@echo "Deploying dotfiles with stow..."
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  stow $$pkg"; \
		stow --restow --target=$(HOME) $$pkg; \
	done
	@echo "Done."

# --- Stow variants ---

stow-dry:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@echo "=== DRY RUN ==="
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "--- $$pkg ---"; \
		stow --verbose --no --target=$(HOME) $$pkg; \
	done

stow-home:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	cd $(DOTDIR) && stow --restow --target=$(HOME) home

stow:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  stow $$pkg"; \
		stow --restow --target=$(HOME) $$pkg; \
	done

# --- Backup ---

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

# --- Clean ---

clean:
ifndef STOW
	$(error "GNU Stow not found.")
endif
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
	@echo "  all / install   Check deps + deploy all dotfiles (default)"
	@echo "  check-deps      Check which required tools are installed"
	@echo "  stow-dry        Dry run -- show what stow would do"
	@echo "  stow-home       Deploy only home configs"
	@echo "  backup          Backup existing non-symlinked dotfiles"
	@echo "  clean           Remove all stow-managed symlinks"
	@echo "  help            Show this message"
	@echo ""
	@echo "First run: make backup && make"
