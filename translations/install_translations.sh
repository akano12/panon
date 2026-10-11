#!/bin/sh
# Install the translations to ~/.local/share/locale, to test them without packaging.
cd "$(dirname "$0")"
mkdir -p build
cd build
cmake ..
make install DESTDIR=~/.local/share/locale/
