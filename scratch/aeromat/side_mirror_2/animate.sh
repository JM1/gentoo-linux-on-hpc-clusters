#!/usr/bin/env bash

set -e
set -x

prefix=car

[ -e "${prefix}.para" ] || exit 255

archive_path="$PWD/archive"

for tag in \
    original \
    pca_0 \
    pca_1 \
    pca_2 \
    pca_3 \
    pca_4 \
    pca_5-last \
    pca_centered_normalized_all \
    pca_centered_normalized_0-last \
    pca_centered_normalized_none \
    pca_centered_normalized_keep-centered_0 \
    pca_centered_normalized_keep-centered_1 \
    pca_centered_normalized_keep-centered_2 \
    pca_centered_normalized_keep-centered_3 \
    pca_centered_normalized_keep-centered_4-last \
    pca_centered_normalized_keep-centered_0-last \
    pca_centered_normalized_0-2; \
do
    (
        set -e
        set -x
        base_path="$PWD"
        
        file_prefix="${prefix}_${tag}"
        
        png_listings0="$(find "$archive_path/$file_prefix" -maxdepth 1 -name "png-*" -print -quit)"
        if [ -n "$png_listings0" ]; then
            echo "png dir $png_listings0 found, skipping $file_prefix"
            exit 0
        fi
        
        vtk_dir="$archive_path/$file_prefix/vtk"
        if [ ! -d "$vtk_dir" ]; then
            echo "$vtk_dir not found, skipping $file_prefix"
            exit 0
        fi
        
        cd "$vtk_dir"
        pvpython --force-offscreen-rendering ../../../animate.py -v -v -v --tags $tag
        
        cd "$base_path"
        ./archive.sh
    )
done
