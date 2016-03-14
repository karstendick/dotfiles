#!/usr/bin/env bash
ssh core <<'EOF'
sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev &&
  if [ ! -d the_silver_searcher ]; then git clone git@github.com:ggreer/the_silver_searcher.git; fi &&
  cd the_silver_searcher &&
  git checkout 0.31.0 &&
  ./build.sh &&
    sudo make install
EOF

