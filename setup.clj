(ns setup
  (:require
   [clojure.java.shell :as sh]
   [clojure.pprint :as pp]
   [clojure.java.io :as io]))

(declare installed?)

(def banner (-> "banner.txt" io/resource slurp))

(def system (delay (as-> {:os (System/getProperty "os.name")
                          :arch (System/getProperty "os.arch")} $
                     (assoc $ :win? (re-find #"Windows" (:os $))))))

(def components
  (delay {:jvm {:installed? (installed? "javac")}
          :git {:installed? (installed? "git")}
          :clojure {:installed? (installed? "clojure")}
          :vscode {:installed? (installed? "code")}
          :calva {:installed? false}}))

(defn installed? [app]
  (zero? (:exit (if (:win? @system)
                  (sh/sh "powershell" "-Command" "where.exe" app)
                  (sh/sh "which" app)))))

(defn download-installer [])

(defn install-git [git]
  (when-not (:installed? git)))

(defn install-jvm [])

(defn install-clojure [])

(defn install-vscode [])

(defn install-calva [])

(defn -main []
  (println banner)
  (install-git (:git @components))
  (install-jvm)
  (install-clojure)
  (install-vscode)
  (install-calva))

(-main)
