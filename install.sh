#!/bin/bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

echo "Installing dotfiles from $DOTFILES_DIR"

# Backup function
backup_if_exists() {
    local target=$1
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing $target to $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        echo "Removing existing symlink $target"
        rm "$target"
    fi
}

# Create symlink function
create_symlink() {
    local source=$1
    local target=$2
    backup_if_exists "$target"
    echo "Linking $target -> $source"
    ln -s "$source" "$target"
}

# Ensure .config directory exists
mkdir -p "$CONFIG_DIR"

# Symlink config directories
echo ""
echo "Setting up ~/.config symlinks..."
for dir in "$DOTFILES_DIR"/config/*/; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        create_symlink "$dir" "$CONFIG_DIR/$dirname"
    fi
done

# Symlink config files (at root of config/)
for file in "$DOTFILES_DIR"/config/.*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        create_symlink "$file" "$CONFIG_DIR/$filename"
    fi
done

for file in "$DOTFILES_DIR"/config/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        create_symlink "$file" "$CONFIG_DIR/$filename"
    fi
done

# Symlink shell configs from root
echo ""
echo "Setting up shell config symlinks..."
for file in zshrc aliases gitconfig gemrc bash_env gitignore_global p10k.zsh tmux.conf gitmessage; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        create_symlink "$DOTFILES_DIR/$file" "$HOME/.$file"
    fi
done

# Install Homebrew packages
echo ""
echo "Installing Homebrew packages..."
if command -v brew &>/dev/null; then
    # Install GNU grep first (required by this script if bash_env alias is active)
    if ! brew list grep &>/dev/null; then
        echo "Installing grep..."
        brew install grep
    else
        echo "grep already installed"
    fi

    # Define packages and casks to install
    PACKAGES=(
        "powerlevel10k"
        "neovim"
        "fzf"
        "lazygit"
        "watchexec"
        "fd"
        "ripgrep"
        "universal-ctags"
        "tmux"
        "atuin"
        "gh"
    )

    CASKS=(
        "font-meslo-lg-nerd-font"
    )

    # Get list of installed packages once
    INSTALLED_PACKAGES=$(brew list --formula -1)
    INSTALLED_CASKS=$(brew list --cask -1)

    # Check regular packages
    TO_INSTALL=()
    for pkg in "${PACKAGES[@]}"; do
        if ! echo "$INSTALLED_PACKAGES" | grep -q "^${pkg}$"; then
            TO_INSTALL+=("$pkg")
        else
            echo "$pkg already installed"
        fi
    done

    # Install missing packages in one command
    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo "Installing packages: ${TO_INSTALL[*]}"
        brew install "${TO_INSTALL[@]}"
    fi

    # Check casks
    TO_INSTALL_CASKS=()
    for cask in "${CASKS[@]}"; do
        if ! echo "$INSTALLED_CASKS" | grep -q "^${cask}$"; then
            TO_INSTALL_CASKS+=("$cask")
        else
            echo "$cask already installed"
        fi
    done

    # Install missing casks in one command
    if [ ${#TO_INSTALL_CASKS[@]} -gt 0 ]; then
        echo "Installing casks: ${TO_INSTALL_CASKS[*]}"
        brew install --cask "${TO_INSTALL_CASKS[@]}"
    fi
else
    echo "Warning: Homebrew not found. Skipping package installation."
    echo "Please install Homebrew from https://brew.sh"
fi

# Check for Xcode Command Line Tools
echo ""
if ! command -v make &>/dev/null; then
    echo "=========================================="
    echo "⚠️  WARNING: Xcode Command Line Tools Missing"
    echo "=========================================="
    echo "Neovim's Telescope plugin requires 'make' to build."
    echo "Install with: xcode-select --install"
    echo "=========================================="
fi

# Clone fzf-git if not present
echo ""
if [ ! -d "$HOME/.fzf-git" ]; then
    echo "Cloning fzf-git.sh..."
    git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/.fzf-git"
else
    echo "fzf-git.sh already installed"
fi

# Clone catppuccin tmux theme if not present
if [ ! -d "$HOME/.tmux/catppuccin" ]; then
    echo "Cloning catppuccin tmux theme..."
    mkdir -p "$HOME/.tmux"
    git clone https://github.com/catppuccin/tmux.git "$HOME/.tmux/catppuccin"
else
    echo "catppuccin tmux theme already installed"
fi

echo ""
echo "Done! Dotfiles installed."
echo "Note: Some configs (prr, shortcut-cli) are excluded for security."
echo ""
echo "=========================================="
echo "⚠️  MANUAL STEP REQUIRED - iTerm2 Setup"
echo "=========================================="
echo "1. Import color scheme:"
echo "   - Preferences (Cmd + ,) → Profiles → Colors → Color Presets → Import"
echo "   - Select: ~/.dotfiles/config/iterm2/dev-iterm-profile.itermcolors"
echo ""
echo "2. Set font (for icons in prompt):"
echo "   - Profiles → Text → Font"
echo "   - Select: 'MesloLGS Nerd Font Mono' (size 12-14)"
echo ""
echo "Terminal.app users:"
echo "  1. Go to Preferences (Cmd + ,)"
echo "  2. Go to Profiles → Font → Change"
echo "  3. Search for 'MesloLGS' and select 'MesloLGS Nerd Font Mono'"
echo "=========================================="
echo ""
echo "=========================================="
echo "⚠️  OPTIONAL - Ruby LSP Setup"
echo "=========================================="
echo "For full nvim LSP support in Ruby projects, install ruby-lsp:"
echo ""
echo "  gem install ruby-lsp"
echo ""
echo "Or add to your project's Gemfile (recommended):"
echo "  gem 'ruby-lsp', require: false"
echo "=========================================="
