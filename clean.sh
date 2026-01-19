#!/bin/sh
find . \( -iname ':2eDS_Store' \
    -o -iname '.DS_Store' \
    -o -iname '.AppleDouble' \
    -o -iname 'Network Trash Folder' \
    -o -iname 'Temporary Items' \
    -o -iname ':2eTemporary Items' \
    -o -iname '.Temporary Items' \
    -o -iname ':2elocalized' \
    -o -iname '.localized' \
    -o -iname ':2e_*' \
    -o -iname '._*' \) -exec rm -rf {} \;
