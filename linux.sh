#!/bin/sh

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

And a couple other helpful tools to get you going.
"

arch="$ARCHFLAGS"
repo="https://github.com/nixin72/clj-setup"

Green=$'\e[0;32m'
Red=$'\e[0;31m]'
End=$'\e[m'

brew_sh="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
clj_sh="https://download.clojure.org/install/linux-install-1.11.1.1113.sh"
jdk_tar="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.1.0/graalvm-ce-java11-linux-amd64-22.1.0.tar.gz"
code_rpm="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
rlwrap_rpm="https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/36/Everything/x86_64/os/Packages/r/rlwrap-0.45.2-1.fc36.x86_64.rpm"

log() {
    echo "$Green[$(date "+%H:%M:%S")]$End $@"
}

error() {
    echo "$Red[$(date "+%H:%M:%S")]$End Error: $@"
    echo "If you believe this is an issue with clj-setup, please leave an issue on our GitHub repository $repo."
}

installed() {
    type "$1" > /dev/null 2>&1
}

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

log_sucess() {
    if installed $1; then
        log "$2 is now installed!"
    else
        error "Failed to install $2"
    fi
}

install_x() {
    log "Looks like you're using a $1 based system. We're going to try to install using $2."
}

run_script() {
    chmod +x tmp.sh
    sudo ./tmp.sh >> /dev/null
    rm tmp.sh
}

install_script() {
    curl -sSfL "$1" -o tmp.sh >> /dev/null
    if yes_or_no "Would you like to inspect the install script?"; then
        less tmp.sh
        if yes_or_no "Would you like to continue installing this?"; then
            run_script
        else
            return 1
        fi
    else
        run_script
    fi
}

install_rpm() {
    curl -sSfL "$1" -o tmp.rpm >> /dev/null
    sudo rpm -i tmp.rpm >> /dev/null
    rm tmp.rpm
}

##################################################
########### Linux ################################
##################################################

install_git() {
    if installed git; then
        log "Git already installed"...
    else
        log "Installing git..."
        if installed apt; then sudo apt install git
        elif installed yum; then sudo yum install git
        elif installed dnf; then sudo dnf install git
        elif installed pacman; then sudo pacman -S git
        else error "Unknown system - don't know how to install git."
        fi
    fi
}

install_java() {
    if installed javac; then
        log "JDK already installed..."
    else
        log "Installing GraalVM JDK..."
        sudo mkdir /usr/lib/jvm
        curl -sSfL "$jdk_jar" -o graal.tar.gz
        tar -xzf graal.tar.gz
        mv graal

        log_sucess javac "JDK"
    fi
}

install_rlwrap() {
    if installed rlwrap; then
        log "rlwrap already installed..."
    else
        log "Installing rlwrap..."

        git clone https://github.com/hanslub42/rlwrap.git
        cd rlwrap
        ./configure
        make
        sudo make install

        log_sucess rlwrap "rlwrap"
    fi
}

install_clojure() {
    if installed clojure; then
        log "Clojure already installed..."
    else
        log "Installing Clojure..."
        install_script "$clj_sh"
        log_sucess clojure "Clojure"
    fi
}

install_vscode() {
    if installed code; then
        log "Visual Studio Code already installed..."
    else
        log "Installing Visual Studio Code"
        log_sucess code "Visual Studio Code"
    fi
}

install_linux() {
    log "Unknown linux distribution... Going to do a manual install."
    install_git
    install_java
    install_rlwrap
    install_clojure
    install_vscode
}

install_debian() {
    install_x "Debian" "apt"
    sudo apt install -y git rlwrap clojure visual-studio-code
}

install_arch() {
    install_x "Arch" "pacman";
    echo "Installing with pacman..."
    sudo pacman -Sy git rlwrap clojure vscode
}

install_fedora() {
    install_x "Fedora-like" "rpm";
    log "Installing Visual Studio Code..."
    install_rpm "$code_rpm"
    log "Installing rlwrap..."
    install_rpm "$rlwrap_rpm"
    install_clojure
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
    echo "Installing Homebrew. This will greatly simplify installing everything else."
    install_script "$brew_sh"
    install_brew
}

##################################################
########### Run Installations ####################
##################################################

install_extensions() {
    log "Installing vscode extensions..."
    code --install-extension betterthantomorrow.calva >> /dev/null
    code --install-extension borkdude.clj-kondo >> /dev/null
}

install_clojure_tools() {
    log "Installing deps-new"
    clojure -Ttools install io.github.seancorfield/deps-new \
        '{:git/tag "v0.4.9"}' :as new >> /dev/null
}

run_install() {
    case "$(uname -s)" in
        Darwin)
            if installed brew; then install_brew
            elif installed ports; then install_ports
            else install_macos
            fi
            ;;

        Linux)
            if installed pacman; then install_arch
            elif installed apt; then install_debian
            elif installed rpm; then install_fedora
            else install_linux
            fi
            ;;

        *) log "Unrecognized OS type." ;;
    esac

    install_extensions
    install_clojure_tools

    log "And looks like that's it!"

    echo -e "\n\n$Green---  New to Clojure? ---$End"
    echo "Check out these free resources to help you get started:"
    echo " - [Book] https://www.braveclojure.com/clojure-for-the-brave-and-true/"
    echo " - [Video] "
    echo " - [Docs] https://clojure.org/api/cheatsheet"
    echo " - [Slack] https://clojurians.net/"
    echo " - [Discord] https://discord.gg/discljord"
}

if yes_or_no "Would you like to continue?"; then
    run_install
else
    echo "Stopping installation..."
fi


echo "
After installing these 4 applications, there will be a handful more optional ones that you'll have the choice of installing along with these.

These extra tools are purely optional, but are recommended - particularly if you're new to Clojure.
"
