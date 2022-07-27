# Clj-Setup

A tool to quickly and easily set up a Clojure environment on your computer! It provides:
- Git 
- A JVM (OpenJDK or GraalVM)
- The Clojure compiler 
- Visual Studio Code as a text editor
- Calva and Clj-Kondo extensions to vscode
- A couple Clojure command line utilities (cljfmt, deps-new)

# Installation

## Linux & MacOS 

If you're using bash, sh, zsh, etc., then paste this into your shell.

```sh
sh <(curl --proto '=https' -sSf https://raw.githubusercontent.com/nixin72/clj-setup/main/setup.sh)
```

If you're using Fish, or you just want to take a look at what the script 
is doing before you run it, do these instead: 

```fish
$ curl --proto '=https' -sSfO https://raw.githubusercontent.com/nixin72/clj-setup/main/setup.sh
$ chmod +x setup.sh
$ ./setup.sh
```

