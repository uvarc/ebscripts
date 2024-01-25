#!/bin/bash
# Ruoshi Sun
# 2024-01-24

HERE=$(realpath $(dirname $0))
EBVER=4.7.1

# files to be excluded in easyblock dir
EXCLUDE="__init__.py
__pycache__
*.pyc
*.pyo"

EXCLUDE=$(echo "$EXCLUDE"|sed 's/^/--exclude /'|tr '\n' ' ')
TMP=$(mktemp -d)
DIVIDER=$(printf %"$COLUMNS"s|tr ' ' '-')

if [ $# -eq 1 ]; then
    # dry run
    echo "DRY RUN - no changes will be made in $HERE"
    RSYNCFLAG=-nav
else
    RSYNCFLAG=-qav
fi

function sync() {
    # collect all files in a temp dir first and then bulk rsync later to capture deleted modules
    cd $SOFTWAREDIR/$1
    find . -mindepth $2 -maxdepth $2 -type f \( -name *.eb -or -name *.patch \) \
        -exec rsync -qav {} $TMP \;
}

# Initialize variables
module purge
if [ "$(hostname)" = "build" ]; then
    export MODULEPATH=/apps/modulefiles:$MODULEPATH
    ml easybuild/$EBVER || {
        echo "Failed to load EasyBuild"
        exit 1
    }
    EBDIR=$EBROOTEASYBUILD
    PYVER=$($EB_INSTALLPYTHON -V|awk '{print $2}') # e.g. 3.6.8
    PYVER=${PYVER%.*}                              # e.g. 3.6
    EASYBLOCKSDIR=$EBDIR/lib/python${PYVER}/site-packages/easybuild/easyblocks/
    SOFTWAREDIR=${EASYBUILD_INSTALLPATH}/${EASYBUILD_SUBDIR_SOFTWARE}
else
    APPSDIR="$(realpath /apps)_build"
    EBDIR=$APPSDIR/software/EasyBuild/$EBVER
    PYTHON=/usr/bin/python3
    PYVER=$($PYTHON -V|awk '{print $2}') # e.g. 3.6.8
    PYVER=${PYVER%.*}                    # e.g. 3.6
    echo "Not on build node. Assuming:"
    echo "- EB in $EBDIR"
    echo "- software stack in $APPSDIR/software/standard"
    echo "- python $PYTHON"
    EASYBLOCKSDIR=$APPSDIR/software/EasyBuild/$EBVER/lib/python${PYVER}/site-packages/easybuild/easyblocks/
    SOFTWAREDIR=$APPSDIR/software/standard
fi

# Configuration
echo $DIVIDER
echo "EasyBuild:   $EBDIR"
echo "Easyconfigs: $SOFTWAREDIR"
echo "Easyblocks:  $EASYBLOCKSDIR"
echo $DIVIDER

# easyconfigs
echo -n "Syncing installed easyconfigs and patches... "
sync core       4
sync compiler   6
sync mpi        8
sync toolchains 4
sync container  6
rsync $RSYNCFLAG --delete $TMP/ $HERE/easyconfigs
rm -rf $TMP
echo "Done."
echo $DIVIDER

# easyblocks
echo -n "Syncing easyblocks... "
rsync $RSYNCFLAG $EXCLUDE "$EASYBLOCKSDIR" $HERE/easyblocks
echo "Done."
echo $DIVIDER
echo "Completed on $(date)."
