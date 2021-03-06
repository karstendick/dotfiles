{:user {:plugins [[lein-pprint "1.1.1"]
                  [lein-kibit "0.0.8"]
                  [jonase/eastwood "0.2.0"]
                  [cider/cider-nrepl "0.8.1"]]
        :dependencies [[slamhound "1.3.1"]
                       [midje "1.7.0"]
                       [pjstadig/humane-test-output "0.8.1"]]
        :injections [(require 'pjstadig.humane-test-output)
                     (pjstadig.humane-test-output/activate!)]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
