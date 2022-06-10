#!/bin/sh

arch="$ARCHFLAGS"
repo="https://github.com/nixin72/clj-setup"

using_pm() {
    echo "Now we're gonna check to make sure everything installed properly."
    echo "If your package manager failed to install something, we'll try installing it manually instead."
}

Green=$'\e[0;32m'
End=$'\e[m'

log() {
    echo "$Green[$(date "+%H:%M:%S")]$End $@"
}

log "Thank you for using clj-setup!"
log "Let's get a Clojure environment ready for you real quick."
echo ""

# Just do it all through the system package manager
if which yay && yay --version | grep yay; then yay -S jdk11-graalvm-bin clojure vscode; using_pm
elif paru --version; then paru -S jdk11-graalvm-bin clojure vscode; using_pm
elif brew --version; then brew install openjdk@11 clojure visual-studio-code; using_pm
elif dnf --version; then sudo dnf install java-11-openjdk.x86_64 clojure; using_pm
elif yup --version; then sudo yum install jdk11-graalvm-bin clojure vscode; using_pm
elif rpm --version; then sudo rpm install jdk11-graalvm-bin clojure vscode; using_pm;
elif apt --version; then
    log "Just need to update and add GPG key before we can continue..."
    sudo apt update
    sudo apt install software-properties-common apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt update
    
    log "Okay, now we can install everything!"
    sudo apt install openjdk-11-jdk clojure code
    using_pm
else 
    log "You're not using any package manager (or at least not one I know how to use), so we're going to install everything manually..."
    log "If this looks like a mistake, please let me know at $repo"
    echo ""
    log "First things first, we have to install a JVM."
fi 

javac --version 
if [ $? -eq 0 ]; then
    log "Looks like you've already got a JDK installed! Let's move on..."
else
    log "We're going to use GraalVM OpenJDK because it provides some extra nice stuff..."
    sudo mkdir /usr/lib/jvm
    sudo curl -o ~/Downloads/graalvm.tar.gz \
         -L https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.1.0/graalvm-ce-java11-linux-amd64-22.1.0.tar.gz \
        | tar -xf -C /usr/lib/jvm/

    javac --version
    if [ $? -eq 0 ]; then 
        log "Okay, the JDK should be installed correctly. Let's move on..."
    else 
        log "Hmm, something went wrong trying to install the JDK. Try running this script again maybe?"
        log "Please leave a bug report on $repo"
        exit -1
    fi
fi 

log "Next, we should install Clojure itself."
clojure --version 
if [ $? -eq 0 ]; then 
    log "Oh, Clojure is already installed. An IDE next!"
else 
    curl -O https://download.clojure.org/install/linux-install-1.11.1.1113.sh
    chmod +x linux-install-1.11.1.1113.sh
    sudo ./linux-install-1.11.1.1113.sh
    
    clojure --version
    if [ $? -eq 0 ]; then 
        log "Okay, Clojure appears to be installed! An editor next!"
    else 
        log "Hmm, something went wrong trying to install Clojure. Try running this script again maybe?"
        log "Please leave a bug report on $repo"
        exit -1;
    fi
fi 

log "We'll install vscode..."
code --version 
if [ $? -eq 0 ]; then 
    log "Nevermind, vscode is already installed! Let's just get you set up with some extensions then."
else 
    # Check if MacOS to install the correct zip
    #if macos; then 
       # curl -O https://update.code.visualstudio.com/latest/darwin-universal/stable
    #fi

    # curl -o https://download.clojure.org/install/linux-install-1.11.1.1113.sh | unzip
    # chmod +x linux-install-1.11.1.1113.sh
    # sudo ./linux-install-1.11.1.1113.sh
    
    code --version
    if [ $? -eq 0 ]; then 
        log "Okay, Clojure appears to be installed! An editor next!"
    else 
        log "Hmm, something went wrong trying to install Clojure. Try running this script again maybe?"
        log "Please leave a bug report on $repo"
        exit -1
    fi
fi 

# Install VSCode extensions
log "We'll install the CALVA extension for syntax highlighting, autocomplete, REPL, etc..."
code --install-extension betterthantomorrow.calva --force
log "And clj-kondo as a nice linter."
code --install-extension borkdude.clj-kondo --force

# Install Clojure tools
log "Finally, let's install deps-new to create new Clojure projects easily."
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
