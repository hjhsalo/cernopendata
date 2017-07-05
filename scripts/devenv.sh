#!/bin/sh
#
# This file is part of CERN Open Data Portal.
# Copyright (C) 2017 CERN.
#
# CERN Open Data Portal is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# CERN Open Data Portal is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CERN Open Data Portal; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307, USA.
#
# In applying this license, CERN does not
# waive the privileges and immunities granted to it by virtue of its status
# as an Intergovernmental Organization or submit itself to any jurisdiction.

script_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

input_file="./devmodules.lst"


generate_license () {
echo "# -*- coding: utf-8 -*-"
echo "#"
echo "# This file is part of CERN Open Data Portal."
echo "# Copyright (C) 2017 CERN."
echo "#"
echo "# CERN Open Data Portal is free software; you can redistribute it"
echo "# and/or modify it under the terms of the GNU General Public License as"
echo "# published by the Free Software Foundation; either version 2 of the"
echo "# License, or (at your option) any later version."
echo "#"
echo "# CERN Open Data Portal is distributed in the hope that it will be"
echo "# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of"
echo "# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU"
echo "# General Public License for more details."
echo "#"
echo "# You should have received a copy of the GNU General Public License"
echo "# along with CERN Open Data Portal; if not, write to the"
echo "# Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
echo "# MA 02111-1307, USA."
echo "#"
echo "# In applying this license, CERN does not"
echo "# waive the privileges and immunities granted to it by virtue of its status"
echo "# as an Intergovernmental Organization or submit itself to any jurisdiction."

}


generate_requirements_txt () {

    flag_flask_ipython=$(echo "$@" | grep -oe "--\<flask_ipython\>")
    flag_flask_debugtoolbar=$(echo "$@" | grep -oe "--\<debugtoolbar\>")

    content=""
    file="$script_dir/../requirements-extra.txt"

    if [ -s "$file" ]; then
        content=$(grep -E '^(#)' "$file")
    else
        generate_license >> "$file"
    fi

    content="$content\n"

    # FIXME: Take modulelist as a parameter and not from directory listing.
    for entry in "$script_dir/../devmodules"/*
    do
      # echo "-e file:///code/devmodules/${entry##*/}"
      content="$content\n-e file:///code/devmodules/${entry##*/}"
    done

    # TODO: Add options to include Flask-IPython and Flask-Debugtoolbar
    echo "$content" > "$file"
}


check_for_git () {
    # Check that git-executable is found
    # From: https://stackoverflow.com/a/677212
    command -v git >/dev/null 2>&1 ||
        { echo >&2 "Git executable is required but ";
          echo >&2 "not installed.  Canceling.";
          exit 1; }
}


generate_repolist_and_download_modules () {

    repolist=""

    # Read in repolist entries from file.
    # From: https://stackoverflow.com/a/24537755
    echo "Searching for development modules in devmodules.lst...\n"
    repolist=$(grep -vE '^(\s*$|#)' "$input_file" | sort -u)

    if [ "$repolist" = "" ]; then
        echo "No development modules defined in devmodules.lst\n"
    else
        echo "Adding modules: \n$repolist\n"
    fi


    # Read in repolist entries from envvar if it exists.
    repolist_envvar=${COD_DEVMODULES-""}
    if [ "$repolist_envvar" != "" ]; then
        # TODO: Append URL to repolist
        echo "Searching for development modules in \$COD_DEVMODULES\n"
        echo "Adding modules: \n\n"

    else
        echo "No development modules defined in \$COD_DEVMODULES\n"
    fi


    # Remove duplicates from the repolist
    #repolist=$(echo "$repolist" | tr ' ' '\n' | sort | uniq | tr '\n' ' ')
    repolist=$(echo "$repolist" | tr ' ' '\n' | sort | uniq)


    # Present a list of modules to be downloaded
    # Ask for confirmation
    echo "Following modules will be downloaded: \n$repolist\n"
    echo "Continue downloading?"
    echo "(Y)es or (n)o: "

    read confirmdownload

    if [ "$confirmdownload" = "Y" ]; then

        echo "\n"

        # Check if devmodules exists.
        # Ask for confirmation to overwrite (delete).
        # Otherwise exit
        if [ -d "$script_dir/../devmodules" ]; then
            echo "devmodules-folder already exists!"
            echo "Script will delete contents of devmodules-folder!"
            echo "Any uncommitted changes will be lost!"
            echo "Are you sure you want to continue?"
            echo "(Y)es or (n)o: "

            read confirmdelete

            if [ "$confirmdelete" = "Y" ]; then
                echo "\n"
                echo "Deleting contents of devmodules-folder...\n"
                rm -rf "$script_dir/../devmodules"
                mkdir "$script_dir/../devmodules"
                echo "Deleted\n"
            else
                echo "\nCancelled\n"
                exit 1
            fi
        else
            mkdir "$script_dir/../devmodules"
        fi

        # Change to devmodules folder and try to clone each entry of repolist.
        cd "$script_dir/../devmodules"
        for i in $repolist
        do
            echo "cloning $i"
            git clone $i
        done

        echo "Generating requirements-extra.txt with new modules...\n"
        generate_requirements_txt

        echo "\nDone\n"

    else
        echo "\nCancelled\n"
        exit 1
    fi

    exit 0
}


usage () {
    # FIXME: Better instructions
    echo "${0##*/} Setups a development environment"
    echo ""
    echo "Usage:"
    echo "  init                   Initializes a development environment."
    echo "  -h                     Help"
}


if [ "$1" != "" ]
then
    case $1 in
        init)              generate_repolist_and_download_modules
                           ;;
        -h | --help )      usage
                           exit
                           ;;
    esac
else
    usage
fi





