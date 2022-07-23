#!/bin/sh

arch="$ARCHFLAGS"
repo="https://github.com/nixin72/clj-setup"

Green=$'\e[0;32m'
End=$'\e[m'

log() {
    echo "$Green[$(date "+%H:%M:%S")]$End $@"
}

echo "
   ________        __     _____ ______________  ______
  / ____/ /       / /    / ___// ____/_  __/ / / / __ \\
 / /   / /   __  / /____ \__ \/ __/   / / / / / / /_/ /
/ /___/ /___/ /_/ /____/___/ / /___  / / / /_/ / ____/
\____/_____/\____/     /____/_____/ /_/  \____/_/

Thank you for using clj-setup to set up your Clojure environment.

This tool will install several components on your system, including:

- Git
- A Java Virtual Machine
- The Clojure compiler
- Visual Studio Code
- Calva

Some of these you may already have installed. If that's the case, clj-setup will simply skip those tools.

After installing these 4 applications, there will be a handful more optional ones that you'll have the choice of installing along with these.

These extra tools are purely optional, but are recommended - particularly if you're new to Clojure.
"

yes_or_no() {
    while true; do
        read -p "$* [Y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) return 1  ;;
            *) return  0 ;;
        esac
    done
}

install_x() {
    log "Looks like you're using a $1 based system. We're going to try to install using $2."
}

##################################################
########### Linux ################################
##################################################
install_debian() {
    install_x "Debian" "apt"
    sudo apt install -y git clojure visual-studio-code
}

install_arch() {
    install_x "Arch" "pacman";
    echo "Installing with pacman..."
    # sudo apt install -y git clojure visual-studio-code
}

install_dnf() {
    install_x "" "dnf";
    echo "Installing with dnf..."
    # sudo dnf install java-11-openjdk.x86_64 clojure
}

install_yum() {
    install_x "" "yum";
    echo "Installing with yum..."
    # sudo yum jdk11-graalvm-bin clojure vscode
}

install_rpm() {
    install_x "" "rpm";
    echo "Installing with rpm..."
    # sudo rpm install jdk11-graalvm-bin clojure vscode
}

install_linux() {
    echo "Unknown linux distribution... Going to do a manual install."
}

##################################################
########### MacOS ################################
##################################################
install_brew() {
    install_x "MacOS" "brew"
    brew install -q git openjdk@11 clojure visual-studio-code
}

install_ports() {
    install_x "MacOS" "ports"
    echo "Installing with MacPorts..."
    # sudo port install git openjdk11 clojure visual-studio-code
}

install_macos() {
    # If they don't have brew, just install brew for them...
    # It's way easier this way.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    install_brew
}

##################################################
########### Run Installations ####################
##################################################

run_install() {
    case "$(uname -s)" in
        Darwin)
            if type brew; then install_brew
            elif type ports; then install_ports
            else install_macos
            fi
            ;;

        Linux)
            if type pacman; then install_arch
            elif type apt; then install_debian
            elif type dnf; then install_dnf
            else install_linux
            fi
            ;;

        *)
            log "Unrecognized OS type."
    esac

    log "Installing vscode extensions..."
    code --install-extension betterthantomorrow.calva
    code --install-extension borkdude.clj-kondo
}

if yes_or_no "Would you like to continue?"; then
    run_install
else
    echo "Stopping installation..."
fi
