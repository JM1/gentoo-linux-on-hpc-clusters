#!/usr/bin/env bash

set -e
set -x

ulimit -s unlimited # prevent "argument list too long" errors

prefix=car

[ -e "${prefix}.para" ] || exit 255

archive_path="$PWD/archive"

if [ ! -e "$archive_path" ]; then
    mkdir "$archive_path"
fi

grid_filename="${prefix}.grid"
grid_dir="$archive_path/grid"
grid_path="$grid_dir/$grid_filename"
if [ ! -e "$grid_dir" ]; then
    mkdir -p "$grid_dir"
    ln -s "$(readlink -f "$grid_filename")" "$grid_path"
fi

case_exts="case geo"
case_basename="$grid_filename"
case_dir="$archive_path/ensight"
case_basepath="$case_dir/$case_basename"
if [ -e "${case_basename}.case" ]; then
    [ -e "$case_dir" ] && mv -i "$case_dir" "$case_dir.$(date +%Y%m%d%H%M%S --reference "$case_dir")"
    mkdir -p "$case_dir"
    for ext in $case_exts; do
        mv -i "$case_basename.$ext" "$case_dir/"
    done
fi

tags="
original
pca_0
pca_1
pca_2
pca_3
pca_4
pca_5-last
pca_centered_normalized_all
pca_centered_normalized_0-last
pca_centered_normalized_none
pca_centered_normalized_keep-centered_0
pca_centered_normalized_keep-centered_1
pca_centered_normalized_keep-centered_2
pca_centered_normalized_keep-centered_3
pca_centered_normalized_keep-centered_4-last
pca_centered_normalized_keep-centered_0-last
pca_centered_normalized_0-2
"

# To do less directory listings and thus improve performance,
# we move all pval files before continueing with pvd files...
for tag in $tags; do
    file_prefix="${prefix}_${tag}"
    
    pval_dir="$archive_path/$file_prefix/pval"
    pval_listings0="$(find . -maxdepth 1 -name "${file_prefix}.pval.*" -print -quit)"
    if [ -n "$pval_listings0" ]; then
        [ -e "$pval_dir" ] && mv -i "$pval_dir" "$pval_dir.$(date +%Y%m%d%H%M%S --reference "$pval_dir")"
        mkdir -p "$pval_dir"
        ln -s "$(realpath -s -m --relative-to "$pval_dir" "$grid_path")" "$pval_dir/$grid_filename"
        mv -i "${file_prefix}".pval.* "$pval_dir"/
    fi
    
    stat_dir="$archive_path/$file_prefix/stat"
    stat_listings0="$(find . -maxdepth 1 -name "${file_prefix}.stat.*" -print -quit)"
    if [ -n "$stat_listings0" ]; then
        [ -e "$stat_dir" ] && mv -i "$stat_dir" "$stat_dir.$(date +%Y%m%d%H%M%S --reference "$stat_dir")"
        mkdir -p "$stat_dir"
        mv -i "${file_prefix}".stat.* "$stat_dir"/
    fi
done

for tag in $tags; do
    file_prefix="${prefix}_${tag}"
    pval_dir="$archive_path/$file_prefix/pval"
    
    vtk_dir="$archive_path/$file_prefix/vtk"
    if [ -e "${file_prefix}.pvd" ] || [ -e "${pval_dir}/${file_prefix}.pvd" ]; then
        [ -e "$vtk_dir" ] && mv -i "$vtk_dir" "$vtk_dir.$(date +%Y%m%d%H%M%S --reference "$vtk_dir")"
        mkdir -p "$vtk_dir"
        
        for ext in $case_exts; do
            ln -s \
                "$(realpath -s -m --relative-to "$vtk_dir" "$case_basepath.$ext")" \
                "$vtk_dir/$case_basename.$ext"
        done
        
        if [ -e "${file_prefix}.pvd" ]; then
            mv -i             "${file_prefix}"_pval_*vtu             "${file_prefix}".pvd "$vtk_dir"/
        fi
        if [ -e "${pval_dir}/${file_prefix}.pvd" ]; then
            mv -i "${pval_dir}/${file_prefix}"_pval_*vtu "${pval_dir}/${file_prefix}".pvd "$vtk_dir"/
        fi
    fi
done

for tag in $tags; do
    file_prefix="${prefix}_${tag}"
    vtk_dir="$archive_path/$file_prefix/vtk"
    
    for part in magnitude x y z; do
        png_dir="$archive_path/$file_prefix/png-${part}-velocity"
        png_listing0="$(find .          -maxdepth 1 -name "${file_prefix}_${part}-velocity*.[0-9]*.png" -print -quit)"
        if [ -d "${vtk_dir}" ]; then
            png_listing1="$(find "$vtk_dir" -maxdepth 1 -name "${file_prefix}_${part}-velocity*.[0-9]*.png" -print -quit)"
        else
            png_listing1=""
        fi
        
        if [ -n "$png_listing0" ] || [ -n "$png_listing1" ]; then
            [ -e "$png_dir" ] && mv -i "$png_dir" "$png_dir.$(date +%Y%m%d%H%M%S --reference "$png_dir")"
            mkdir -p "$png_dir"
            
            if [ -n "$png_listing0" ]; then
                mv -i            "${file_prefix}_${part}-velocity"*.[0-9]*.png "$png_dir"/
            fi
            if [ -n "$png_listing1" ]; then
                mv -i "${vtk_dir}/${file_prefix}_${part}-velocity"*.[0-9]*.png "$png_dir"/
            fi
        fi
    done
done
