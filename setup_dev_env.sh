#!/bin/bash

# =============================================
# Script Universal para Configurar Ambiente de Desenvolvimento no Linux
# Autor: Wathyson Samuel
# =============================================

set -e  # Sai imediatamente se um comando falhar

# =============================================
# 0. VERIFICA O GERENCIADOR DE PACOTES
# =============================================
echo "🔍 Detectando gerenciador de pacotes..."
if command -v apt &> /dev/null; then
    PKG_MGR="apt"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
else
    echo "❌ Gerenciador de pacotes não suportado."
    exit 1
fi

echo "✅ Gerenciador detectado: $PKG_MGR"

# =============================================
# Função universal para instalar pacotes
# =============================================
install_pkg() {
    case $PKG_MGR in
        "apt") sudo apt update && sudo apt install -y "$@" ;;
        "dnf") sudo dnf install -y "$@" ;;
        "pacman") sudo pacman -Sy --noconfirm "$@" ;;
    esac
}

# =============================================
# 1. INSTALA SNAP E FLATPAK
# =============================================
echo "📦 Instalando Snap e Flatpak..."

if ! command -v snap &> /dev/null; then
    echo "🔧 Instalando Snap..."
    install_pkg snapd
    sudo systemctl enable --now snapd.socket || true
fi

if ! command -v flatpak &> /dev/null; then
    echo "🔧 Instalando Flatpak..."
    install_pkg flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# =============================================
# 2. LINGUAGENS E FERRAMENTAS DE DEV
# =============================================
echo "🔧 Instalando linguagens e ferramentas..."
install_pkg python3 python3-pip git curl wget unzip
install_pkg docker.io || install_pkg docker
install_pkg postgresql mysql-server

# Instalar Node.js via NVM
if ! command -v node &> /dev/null; then
    echo "🌐 Instalando Node.js via NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \ . "$NVM_DIR/nvm.sh"
    nvm install --lts
fi

# Instalar Java 21 via SDKMAN
if ! command -v sdk &> /dev/null; then
    echo "☕ Instalando Java 21 via SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 21.0.3-tem
fi

# Instalar Rust via rustup
if ! command -v rustc &> /dev/null; then
    echo "🦀 Instalando Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# =============================================
# 3. APLICATIVOS E UTILITÁRIOS
# =============================================
echo "🧰 Instalando aplicativos e utilitários..."
install_pkg firefox okular qbittorrent telegram-desktop
install_pkg micro dbeaver

# VS Code
if ! command -v code &> /dev/null; then
    echo "🖥️ Instalando VS Code..."
    if [[ $PKG_MGR == "apt" ]]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
        sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        sudo apt update
        install_pkg code
    else
        flatpak install -y flathub com.visualstudio.code
    fi
fi

# IntelliJ via Toolbox (manual)
if [ ! -d "$HOME/.local/share/JetBrains/Toolbox" ]; then
    echo "🧠 Baixando JetBrains Toolbox..."
    TOOLBOX_URL=$(curl -s https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release | grep -oP 'https.*toolbox.*linux.*tar.gz')
    mkdir -p ~/Downloads && cd ~/Downloads
    wget "$TOOLBOX_URL" -O toolbox.tar.gz
    tar -xzf toolbox.tar.gz -C ~/Downloads
    ./jetbrains-toolbox*/jetbrains-toolbox &
fi

# =============================================
# 4. VISUAL (Ícones, Temas e Fontes)
# =============================================
echo "🎨 Instalando tema Nordic, ícones Papirus e fonte FiraCode..."
install_pkg gnome-tweaks fonts-firacode
install_pkg papirus-icon-theme || flatpak install -y flathub org.kde.PapirusIconTheme

# Nordic GTK Theme
mkdir -p ~/.themes
cd ~/.themes
if [ ! -d "Nordic" ]; then
    git clone https://github.com/EliverLara/Nordic.git
fi

# =============================================
# 5. ZSH E OH-MY-ZSH COM PLUGINS
# =============================================
echo "🐚 Instalando ZSH e Oh My Zsh..."
install_pkg zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Ativa plugins no .zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
chsh -s $(which zsh)

# =============================================
# FIM
# =============================================
echo "✅ Ambiente de desenvolvimento configurado com sucesso! Reinicie o sistema para aplicar totalmente as mudanças."
