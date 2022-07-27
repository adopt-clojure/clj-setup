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

And a couple other helpful tools to get you going.
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
    sudo pacman -Sy git rlwrap clojure vscode
}

install_rpm() {
    log "Installing vscode directly from the .rpm file..."
    curl -L \
        "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" \
        -o vscode.rpm
    sudo rpm -i vscode.rpm
    rm vscode.rpm
}

install_dnf() {
    install_x "Fedoral" "dnf";
    echo "Installing with dnf..."
    sudo dnf install git clojure
    install_rpm
}

install_yum() {
    install_x "Fedora" "yum";
    echo "Installing with yum..."
    sudo yum install git clojure
    install_rpm
}

install_git() {
    echo "Installing git..."
}

install_java() {
    javac --version
    if [ $? -eq 0 ]; then
        log "JDK already installed, skipping."
    else
        log "We're going to use GraalVM OpenJDK because it provides some extra nice stuff..."
        sudo mkdir /usr/lib/jvm
        sudo curl -o ~/Downloads/graalvm.tar.gz \
            -L https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.1.0/graalvm-ce-java11-linux-amd64-22.1.0.tar.gz \
            | tar -xf -C /usr/lib/jvm/

        javac --version
        if [ $? -eq 0 ]; then
            log "JDK installed, moving on..."
        else
            log "Hmm, something went wrong trying to install the JDK. Try running this script again maybe?"
            log "Please leave a bug report on $repo"
            exit -1
        fi
    fi
}

install_clojure() {
    clojure --version
    if [ $? -eq 0 ]; then
        log "Clojure is already installed, skipping."
    else
        # Perhaps send this to $HOME/Downloads or pipe the script into sh
        curl -O https://download.clojure.org/install/linux-install-1.11.1.1113.sh
        chmod +x linux-install-1.11.1.1113.sh
        sudo ./linux-install-1.11.1.1113.sh

        clojure --version
        if [ $? -eq 0 ]; then
            log "Clojure is now installed!"
        else
            log "Hmm, something went wrong trying to install Clojure. Try running this script again maybe?"
            log "Please leave a bug report on $repo"
            exit -1;
        fi
    fi
}

install_vscode() {
    code --version
    if [ $? -eq 0 ]; then
        log "VSCode is already installed, skipping..."
    else

        code --version
        if [ $? -eq 0 ]; then
            log "VSCode is installed."
        else
            log "Hmm, something went wrong trying to install Clojure. Try running this script again maybe?"
            log "Please leave a bug report on $repo"
            exit -1
        fi
    fi
}

install_linux() {
    log "Unknown linux distribution... Going to do a manual install."
    install_git
    install_java
    install_clojure
    install_vscode
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

installed() {
    type $1 >> /dev/null
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
            elif installed dnf; then install_dnf
            else install_linux
            fi
            ;;

        *)
            log "Unrecognized OS type."
    esac

    log "Installing vscode extensions..."
    code --install-extension betterthantomorrow.calva
    code --install-extension borkdude.clj-kondo


    log "Installing deps-new"
    echo "Deps-new is a Clojure tool for generating projects from templates"
    clojure -Ttools install io.github.seancorfield/deps-new '{:git/tag "v0.4.9"}' :as new

    # Done!
    log "And looks like that's it!"

    echo "\n\n$Green---  New to Clojure? ---$End"
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
