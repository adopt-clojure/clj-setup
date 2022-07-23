(ns setup
  (:import [java.lang ProcessBuilder]
           [java.util Scanner]
           [java.io BufferedReader InputStreamReader InputStream])
  (:require
   [clojure.java.shell :as sh]
   [clojure.pprint :as pp]
   [clojure.java.io :as io]
   [clojure.string :as str]
   [clojure.data.json :as json]))

(declare installed?)

(def banner (-> "banner.txt" io/resource slurp))

(def slurp-json (comp #(json/read-str % :key-fn keyword) slurp))

(def system
  (delay (as-> {:os (System/getProperty "os.name")
                :arch (System/getProperty "os.arch")
                :jvm? (installed? "javac")
                :git? (installed? "git")
                :clojure? (installed? "clojure")
                :vscode? (installed? "code")} $
           (assoc $ :win? (re-find #"Windows" (:os $)))
           (assoc $ :mac? (re-find #"Mac" (:os $)))
           ;; Find out if there's a package manager that can be leveraged. If so, makes things much easier
           (merge $ (zipmap
                     [:install-cmd :pm]
                     (cond
                       (installed? "winget")
                       ["winget install $$ --silent --accept-package-agreements --accept-source-agreements" :winget]
                       (installed? "scoop") ["scoop install $$" :scoop]
                       (installed? "brew") ["brew install $$" :brew]
                       (installed? "apt-get") ["sudo apt-get install $$" :apt]
                       (installed? "yum") ["yum install $$" :yum]
                       (installed? "dnf") ["dnf install $$" :dnf]
                       (installed? "emerge") ["sudo emerge --ask --verbose $$" :emerge]
                       (installed? "yay") ["yay -S $$" :yay]
                       (installed? "paru") ["paru -S $$" :paru]
                       (installed? "pacman") ["sudo pacman -S $$" :pacman]
                       (installed? "zypper") ["zypper install $$" :zypper]
                       (installed? "nix-env") ["nix-env -i $$" :nix]
                       (installed? "apk") ["apk add $$" :apk]))))))

(defn installed?
  "Checks if a program is installed"
  [app]
  (zero? (:exit (if (re-find #"Windows" (System/getProperty "os.name"))
                  (sh/sh "powershell" "-Command" "where.exe" app)
                  (sh/sh "which" app)))))

(defn piped-cmd [cmds]
  (let [processes (->> (mapv #(ProcessBuilder. (str/split % #"\s")) cmds)
                       ProcessBuilder/startPipeline)
        result (try
                 (let [is (.getInputStream (last processes))
                       isr (InputStreamReader. is)
                       br (BufferedReader. isr)]
                   (loop [string "" line (.readLine br)]
                     (if line
                       (recur (str string line "\n") (.readLine br))
                       string)))
                 (catch Exception e
                   (prn e)))]
    result))

(defn install-from-cmd
  "Installs a package using the command for the system package manager
  Will also run any extra commands that are sent optionally"
  [system pkg-name & {:keys [pre post]}]
  (if (:install-cmd system)
    (do
      (doseq [cmd pre]
        (apply sh/sh (str/split cmd)))
      (let [cmd (str/split (str/replace (:install-cmd system) #"$$" pkg-name))]
        (apply sh/sh cmd)))
    (throw (ex-info "No package manager" {:type :no-package-manager}))))

(defn install-git-windows []
  (let [asset-url (:assets_url (slurp-json "https://api.github.com/repos/git-for-windows/git/releases/latest"))
        source (->> (slurp-json asset-url)
                    (filter #(re-find #".*64-bit.exe" (:name %)))
                    first
                    :browser_download_url)
        target (str (System/getenv "HOME") "/Downloads")
        download (sh/sh "Invoke-WebRequest" "-Uri" source "-OutFile" target)]
    download))

(defn install-brew
  "If the system is MacOS and brew isn't already installed... Then install brew. It'll just help a lot."
  [system]
  (when (and (:mac? system)
             (nil? (:pm system)))
    (sh/sh "/bin/bash" "-c" "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
    (assoc system
           :install-cmd "brew install"
           :pm :brew)))

(defn install-git
  "Installs git if it's not already present on the system."
  [system]
  (if (:git? system)
    system
    (try
      (install-from-cmd (if (= :emerge (:pm system))
                          "dev-vsc/git"
                          "git"))
      (catch Exception _
        ;; Install manually...
        ))))

(defn install-jvm [system]
  (if (:jvm? system)
    system
    (assoc system :jvm?
           (case (:pm system)
             :brew (install-from-cmd system "openjdk")
             :winget (install-from-cmd system "AdoptOpenJDK.OpenJDK.11")
             :scoop (install-from-cmd system "temurin11-jdk" :pre ["scoop bucket add java"])
             :apt (install-from-cmd system "default-jdk")
             :emerge (install-from-cmd system "virtual/jdk")
             :nix (install-from-cmd system "jdk11")
             (:dnf :yum) (install-from-cmd system "java-11-openjdk")
             (:yay :paru :pacman) (install-from-cmd system "jdk11-openjdk")
             (do
               ;; Install manually...
               )))))

(defn install-clojure
  "Installs Clojure on the user's computer if it's not already installed."
  [system]
  (if (:clojure? system)
    system
    (case (:pm system)
      :brew (install-from-cmd system "clojure/tools/clojure")
      (:yay :paru :pacman :nix) (install-from-cmd system "clojure")
      (do
        (cond
          (:win? system)
          (piped-cmd ["iwr -useb download.clojure.org/install/win-install-1.11.1.1113.ps1" "iex"])
          :else
          (piped-cmd ["curl https://download.clojure.org/install/linux-install-1.11.1.1149.sh" "/bin/sh"]))))))

(defn install-vscode [system]
  (if (:vscode? system)
    system
    (try
      (case (:pm system)
        :brew (install-from-cmd "visual-studio-code")
        :apt (install-from-cmd "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64")
        (:yay :paru :pacman :winget :scoop) (install-from-cmd "vscode"))
      (catch Exception _
        ;; Install manually...
        ))))

(defn install-extensions [system]
  (sh/sh "code" "--install-extension" "betterthantomorrow.calva" "borkdude.clj-kondo"))

(defn -main []
  (println banner)
  (->> (install-brew @system)
       (install-git)
       (install-jvm)
       (install-clojure)
       (install-vscode)
       (install-extensions)))

(-main)
