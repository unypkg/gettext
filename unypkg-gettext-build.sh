#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

apt install -y pkg-config build-essential autoconf bison re2c \
    libxml2-dev

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install python gperf

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="gettext"
pkggit="https://git.savannah.gnu.org/git/gettext.git refs/tags/v[0-9.]*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "v[0-9]([.0-9]+)+$" | tail -n 1)"
latest_ver="$(echo "$latest_head" | cut --delimiter='/' --fields=3 | sed "s|v||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

#cd "$pkg_git_repo_dir" || exit
#./autogen.sh
#cd /uny/sources || exit

rm -rf /uny/pkg/gettext

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="gettext"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

#unset LD_RUN_PATH

./autogen.sh

./configure --prefix=/uny/pkg/"$pkgname"/"$pkgver" \
    --disable-static \
    --docdir=/uny/pkg/"$pkgname"/"$pkgver"/share/doc/gettext

make -j"$(nproc)"
make -j"$(nproc)" check

make install
chmod -v 0755 /uny/pkg/"$pkgname"/"$pkgver"/lib/preloadable_libintl.so

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
