#!/bin/bash
# Copyright (C) 2018-2021 David P. <megver83@parabola.nu>
# Find deprecated Arch packages that are still in our blacklists.
# shellcheck disable=SC2154

usage(){
  # NOTE: the package architecture is always specified with 'parabola', and
  # in 'arch' only when there's an uneeded replacement. This is because your-freedom
  # is for any architecture and no matter if you use Parabola x86_64 or i686, it
  # will always conflict packages that are even for armv7h only (and vice versa).
  # The 'parabola' argument compares with our repositories and Arch's
  # since in blacklists like your-privacy and your-initfreedom we also block
  # some packages from [pcr] (like jitsi) and [libre] (like icedove), and
  # probably also from their -multilib, -testing and -multilib-testing derivatives.

  cat <<EOM
Usage: ${0##*/} [arch|parabola]
Check if there are inexistent packages in the blacklists.

Arguments:
  arch                        Compares ArchLinux{32,ARM} blacklists with their
                              repositories.
  parabola                    Compares Arch & Parabola blacklists with Parabola's
                              and Arch's repos.

Configuration is read from a file called find-deprecated.conf in the same directory
as this script.

To easily remove a package from a blacklist, you can use the following sed expresion:

  sed '/^pkgname:/d' -i blacklist.txt
EOM
}

err(){
  printf '%s==> Error:%s %s\n' \
         "$(tput bold;tput setaf 1)" \
         "$(tput sgr0)" \
         "$1"
  exit 1
}

msg(){
  printf '%s==>%s %s\n' \
         "$(tput bold;tput setaf 2)" \
         "$(tput sgr0)" \
         "$1"
}

submsg(){
  printf '  %s->%s %s\n' \
         "$(tput bold;tput setaf 4)" \
         "$(tput sgr0)" \
         "$1"
}

add(){
  list="$(( list + 1 ))"
}

compare_pkgs(){
  # $1 is the pkgname and replacement (used when checking Arch pkgs)
  # $2 is the packages file list
  local to_be_removed
  local is_not_for
  local to_be_deleted
  local isnt_for
  local arches
  local arch

  # First check if the pkg is available for
  # a specific architecture, if not, check
  # if it's for 'any'
  local package="${1%%:*}"
  local replacement
  replacement="$(echo "$1" | cut -d ":" -f2)"

  for arch in x86_64 i686 armv7h; do
    grep $arch$ "$2" | awk '{print $1}' | grep -xw ^"$package" &> /dev/null || \
    grep any$ "$2" | awk '{print $1}' | grep -xw ^"$package" &> /dev/null || \
    if [ "$2" = "$arch_pkgs" ]; then
      get_libre_pkgs
      # Check if the package has a replacement, and
      # if such replacement is available for the same
      # architectures
      if ! [[ $replacement = "" ]]; then
        # If this works, it means the pkg doesn't exist for $arch in Arch,
        # but we have the [libre] replacement which should be deprecated.
        grep $arch$ "$libre_pkgs" | awk '{print $1}' | grep -xw ^"$replacement" &> /dev/null || \
        grep any$ "$libre_pkgs" | awk '{print $1}' | grep -xw ^"$replacement" &> /dev/null

        case $? in
            0) to_be_removed+=("$arch")
            ;;
            *) is_not_for+=("$arch")
            ;;
        esac
      else
        # However if this fails, it means the pkg doesn't have a replacement
        # for $arch, or it simply doesn't have a replacement.
        is_not_for+=("$arch")
      fi
    elif [ "$2" = "$parabola_pkgs" ]; then
      if [[ -n $replacement ]]; then
        # Look for the replacement
        grep $arch$ "$parabola_pkgs" | awk '{print $1}' | grep -xw ^"$replacement" &> /dev/null || \
        grep any$ "$parabola_pkgs" | awk '{print $1}' | grep -xw ^"$replacement" &> /dev/null

        case $? in
            0) to_be_deleted+=("$arch")
            ;;
            *) isnt_for+=("$arch")
            ;;
        esac
      else
        isnt_for+=("$arch")
      fi
    fi
  done

  # Arch
  if [[ "${is_not_for[*]}" = "x86_64 i686 armv7h" ]]; then
    submsg "$package was not found"
    add
  elif [[ "${to_be_removed[*]}" = "x86_64 i686 armv7h" ]]; then
    submsg "$package was not found, but we've [libre] replacements which should be removed"
    add
  elif [[ -n "${is_not_for[*]}" ]] || [[ -n "${to_be_removed[*]}" ]]; then
    for arch in "${to_be_removed[@]}"; do
      # If the replacement is available for the three arch'es supported
      # by Parabola, then shut up
      for a in x86_64 i686 armv7h; do
        grep -xw "^$replacement $a$" "$libre_pkgs" &> /dev/null && arches+=("$a")
      done
      if ! [[ "${arches[*]}" = "x86_64 i686 armv7h" ]]; then
        submsg "$package ($arch) was not found, but we've a [libre] replacement which should be removed"
        add
      fi
      unset arches
    done
  fi

  # Parabola
  if [[ "${isnt_for[*]}" = "x86_64 i686 armv7h" ]]; then
    submsg "$package was not found"
    add
  elif [[ -n "${isnt_for[*]}" ]]; then
    for arch in "${to_be_deleted[@]}"; do
      submsg "$package ($arch) was not found, but we've $replacement as replacement and should be removed"
      add
    done
  fi
}

mkpkglist_from_mirror(){
  # $1 is the temporary package list file
  local _mirror
  local arch

  # Clean ${1}.1 just in case...
  test -e "${1}.1" && echo > "${1}.1"
  for _mirror in "${mirrors[@]}"; do
    curl -sLf "$_mirror" >> "${1}.1" || err "Connection failed for $_mirror"
  done

  # Create the parsed package list
  grep '".*.pkg.tar.xz"\|".*.pkg.tar.zst"' "${1}.1" | sed "$sedexp" > "$1"
  rm "${1}.1"

  # Separate packages by architecture
  for arch in $supported_architectures; do
      grep "$arch$" "$1" | for f in $(</dev/stdin); do
        echo "${f%-*-*-*} $arch" >> "$1-$arch"
    done
  done
  cat "$1"-{x86_64,i686,armv7h,any} | sort -u > "$1"
  rm "$1"-{x86_64,i686,armv7h,any}
}

check_packages(){
  local pkg_list
  local pkgs

  # shellcheck disable=SC2068
  pkgs="$(grep -hv ^# $@ | awk '{print $1}')"
  pkg_list="$(mktemp)"
  eval "${distro}_pkgs=$pkg_list" # required for compare_pkgs

  msg "Comparing blacklists with ${distro^} packages, this might take a while..."
  case $distro in
        parabola)
          add_parabola_mirrors
          mkpkglist_from_mirror "$parabola_pkgs"
        ;;
        arch)
          mkpkglist_from_mirror "$arch_pkgs"
        ;;
  esac

  # Here the magic begins
  for p in $pkgs; do
    compare_pkgs "$p" "$pkg_list"
  done
  rm "$pkg_list"
}

main(){
  mkmirrorlist
  local distro="$1"

  case $distro in
        parabola)
          check_packages "$blacklists_parabola"
        ;;
        arch)
          check_packages "$blacklists"
          rm "$libre_pkgs"
        ;;
        *)
          err "$1 is not a valid argument"
        ;;
  esac

  if ! [[ $list -gt 0 ]]; then
    submsg 'No packages to show'
  fi
  msg 'done'

  unset list
}

# We'll use this when we check Arch's pkgs only
get_libre_pkgs(){
  local mirrors
  if ! [[ -e $libre_pkgs ]]; then
    libre_pkgs=$(mktemp)
    for r in $repos_libre; do
      mirrors+=("$mirror_parabola/$r/os/x86_64/")
      mirrors+=("$mirror_parabola/$r/os/i686/")
      mirrors+=("$mirror_parabola/$r/os/armv7h/")
    done
    mkpkglist_from_mirror "$libre_pkgs"
  fi
}

# Parabola mirrors, used to check [libre] and [pcr] packages
add_parabola_mirrors(){
  for r in $repos_parabola; do
    mirrors+=("$mirror_parabola/$r/os/x86_64/")
    mirrors+=("$mirror_parabola/$r/os/i686/")
    mirrors+=("$mirror_parabola/$r/os/armv7h/")
  done
}

# Create mirrors lists
mkmirrorlist(){
  unset mirrors
  for r in $repos_x86_64; do
    mirrors+=("$mirror_x86_64/$r/os/x86_64/")
  done
  for r in $repos_i686; do
    mirrors+=("$mirror_i686/i686/$r/")
  done
  for r in $repos_armv7h; do
    mirrors+=("$mirror_armv7h/armv7h/$r/")
  done
}

conf="$(dirname "$(readlink -f "$0")")/find-deprecated.conf"
if test -e "$conf"; then
  # shellcheck disable=SC1090
  . "$conf"
else
  usage
  err "Configuration file not found: $conf"
fi

if [ "$#" -eq 0 ]; then
  usage
else
  for arg in "$@"; do
    main "$arg"
  done
fi
