DOTDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
HOME   := $(or $(HOME),$(shell echo ~))

STOW  := $(shell command -v stow 2>/dev/null)
PACKAGES := home

# Config paths and the binary(s) they need (comma-separated alternatives)
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

.PHONY: all install check-deps stow stow-dry stow-home backup clean force help

all: install

# Check required tools are installed
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

# Backup existing files, remove originals, then stow
install: check-deps
ifndef STOW
	$(error "GNU Stow not found. Install with: sudo pacman -S stow")
endif
	@echo ""
	@backed=0; BACKUP_DIR="$(DOTDIR)backup-$$(date +%Y%m%d-%H%M%S)"; \
	for pkg in $(PACKAGES); do \
		for f in $$(cd $(DOTDIR)$$pkg && find . -type f -o -type l | sed 's|^\./||'); do \
			target="$(HOME)/$$f"; \
			if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
				if [ "$$backed" -eq 0 ]; then \
					echo "=== Backing up conflicting files ==="; \
					mkdir -p "$$BACKUP_DIR"; \
					backed=1; \
				fi; \
				dst="$$BACKUP_DIR/$$f"; \
				mkdir -p "$$(dirname "$$dst")"; \
				cp -a "$$target" "$$dst"; \
				rm -f "$$target"; \
				echo "  moved: $$target -> $$dst"; \
			fi; \
		done; \
	done; \
	if [ "$$backed" -eq 1 ]; then echo "Backup saved to $$BACKUP_DIR"; echo ""; fi; \
	echo "Deploying dotfiles with stow..."; \
	for pkg in $(PACKAGES); do \
		echo "  stow $$pkg"; \
		stow --restow --target=$(HOME) $$pkg; \
	done; \
	echo "Done."

# Dry run
stow-dry:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@echo "=== DRY RUN ==="
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "--- $$pkg ---"; \
		stow --verbose --no --target=$(HOME) $$pkg; \
	done

# Stow only (no backup, will fail on conflicts)
stow:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  stow $$pkg"; \
		stow --restow --target=$(HOME) $$pkg; \
	done

stow-home:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	cd $(DOTDIR) && stow --restow --target=$(HOME) home

# Force: adopt existing files into the stow package instead of backing them up
force:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@echo "=== Adopting existing files into dotfiles repo ==="; \
	for pkg in $(PACKAGES); do \
		echo "  stow --adopt $$pkg"; \
		stow --adopt --restow --target=$(HOME) $$pkg; \
	done; \
	echo ""; \
	echo "WARNING: Existing files were moved INTO the repo."; \
	echo "Run 'git status' and 'git diff' to review changes."

# Backup only (does NOT remove originals, just copies)
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

# Clean: remove all stow symlinks
clean:
ifndef STOW
	$(error "GNU Stow not found.")
endif
	@cd $(DOTDIR) && for pkg in $(PACKAGES); do \
		echo "  unstowing $$pkg"; \
		stow --delete --target=$(HOME) $$pkg 2>/dev/null || true; \
	done
	@echo "Symlinks removed."

# Help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all / install   Backup conflicts, remove originals, deploy symlinks"
	@echo "  check-deps      Check which required tools are installed"
	@echo "  force           Adopt existing files INTO repo (use with caution)"
	@echo "  backup          Copy existing files to backup dir (does not remove)"
	@echo "  stow            Stow without backup (fails on conflicts)"
	@echo "  stow-dry        Dry run -- show what stow would do"
	@echo "  clean           Remove all stow-managed symlinks"
	@echo "  help            Show this message"
	@echo ""
	@echo "First run: make"
