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

# 0. Check that requirements are fulfilled. Basically check that git-executable
# exists

# 1. Check what needs to be installed. From a file and from ENV_VAR.
# Make one single list and check for duplicates.
# Naming either by 1) URL or by 2) Github reference.
# NOTE: Support only for git-protocol.

# 2. Check if folders already exist. If they do, ask for confirmation. TWICE.
# The second confirmation "This script will overwrite any changes you might have
# made. Are you sure you want to continue?"

# 3. Start cloning git repos.
# TODO: Find if it is possible to force overwrite / clone with git or should
# existing folders first be deleted.

# 4. Generate a requirements.txt for installation of development modules.

input_file = "/path/to/file"

repolist = ""

# Check that git-executable is found
# From: https://stackoverflow.com/a/677212
command -v git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }


# Read in repolist entries from file.
# From: https://stackoverflow.com/a/7427305
# From: http://www.digitalinternals.com/script/shell-script-read-file-line-by-line/457/
while IFS="" read -r line; do
    repolist = "$repolist $line"
done < "$input_file"


# Read in repolist entries from envvar if it exists.
repolist_envvar = $COD_DEVMODULES:-}
if [ "$repolist_envvar" != "" ]; then
    # TODO: Append URL to repolist
fi


# Remove duplicates from the repolist
repolist = $(sort -u "$repolist")


# Check if devmodules exists.
# Ask for confirmation to overwrite (delete).
# Otherwise exit
if [ -d "../devmodules" ]; then
    echo "devmodules-folder already exists!"
    echo "This script will overwrite any changes you might have made."
    echo "Are you sure you want to continue?"
    echo "(y)es or (n)o: "

    read confirmdelete

    if [ "$confirmdelete" = "y" ]; then
        echo "Deleting contents of devmodules-folder..."
        #rmdir "../devmodules"
    else
        exit 1
    fi
fi


# Loop through repolist and try to clone each entry.
for i in ${repolist[@]}
do
    $(git clone $i)
    echo "cloning $i"
done
