{:user {:plugins [[lein-pprint "1.1.1"]
                  [lein-kibit "0.0.8"]
                  [venantius/ultra "0.1.9"]
                  [jonase/eastwood "0.2.0"]]
        :ultra  {:color-scheme :solarized_dark}
        :dependencies [[slamhound "1.3.1"]
                       [midje "1.5.0"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
