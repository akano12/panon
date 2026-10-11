#!/bin/bash

#Verify the existence of third party files before packaging.
if [ ! -f "third_party/hsluv-glsl/hsluv-glsl.fsh" ];then
    echo "Cannot find third party files."
    git submodule update --init
fi

# Remove caches
find -L ./plasmoid/contents/scripts -name __pycache__ -type d -prune -exec rm -r {} +
rm -f ./panon.plasmoid

# i18n
mkdir -p build
cd build
cmake ../translations
make install DESTDIR=../plasmoid/contents/locale
cd ..

zip -r panon.plasmoid ./plasmoid
