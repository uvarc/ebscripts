#!/bin/bash
# Ruoshi Sun
# 2024-01-24

if [ ! -z "$(git diff main derp sync.sh)" ]; then
    echo "Error: sync.sh out of sync across branches"
    echo "See README.md for instructions"
    exit 1
fi

#-------------------------------
# Global variables and functions
#-------------------------------
HERE=$(realpath $(dirname $0))
COLUMNS=80

# files to be excluded in easyblock dir
EXCLUDE="__init__.py
__pycache__
*.pyc
*.pyo"

EXCLUDE=$(echo "$EXCLUDE"|sed 's/^/--exclude /'|tr '\n' ' ')
TMP=$(mktemp -d)
DIVIDER=$(printf %"$COLUMNS"s|tr ' ' '-')

# determine YYYYMM for production and derp
YMp=$(basename $(ssh -A login.hpc.virginia.edu realpath /apps))
YMd=$(date -d "${YMp}01 + 6 month" +%Y%m)

function sync() {
    # collect all files in a temp dir first and then bulk rsync later to capture deleted modules
    cd $SOFTWAREDIR/$1
    find . -mindepth $2 -maxdepth $2 -type f \( -name *.eb -or -name *.patch \) \
        -exec rsync -qa {} $TMP \;
}

# check args
if [ $# -eq 0 ]; then
    echo "Usage: `basename $0` p|d [dry]"
    echo "  p = production"
    echo "  d = derp"
    exit 1
fi

if [ $# -ge 2 ]; then
    # dry run
    echo "DRY RUN - no changes will be made in $HERE"
    RSYNCFLAG=-na
else
    RSYNCFLAG=-qa
fi

#----------------------------
# Initialize branch variables
#----------------------------
module purge
case $1 in
    p)
        if [ ! $(git branch --show-current) = "main" ]; then
            echo "Error: trying to sync production into a branch other than main"
            exit 1
        fi
        EBVER=5.0.0
        APPSDIR="/sfs/weka/applications/${YMp}_build"
        PYTHON=/usr/bin/python3
        ;;
    d)
        if [ ! $(git branch --show-current) = "derp" ]; then
            echo "Error: trying to sync derp into a branch other than derp"
            exit 1
        fi
        EBVER=5.0.0
        APPSDIR="/sfs/weka/applications/${YMd}_build"
        PYTHON=/usr/bin/python3
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

EBDIR=$APPSDIR/software/EasyBuild/$EBVER
PYVER=$($PYTHON -V|awk '{print $2}') # e.g. 3.6.8
PYVER=${PYVER%.*}                    # e.g. 3.6
# the trailing slash matters for rsync
EASYBLOCKSDIR=$APPSDIR/software/EasyBuild/$EBVER/lib/python${PYVER}/site-packages/easybuild/easyblocks/
SOFTWAREDIR=$APPSDIR/software/standard

for i in $APPSDIR $EBDIR $EASYBLOCKSDIR $SOFTWAREDIR; do
    if [ ! -d $i ]; then
        echo "Error: $i is not a valid directory"
        exit 1
    fi
done

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

cd $HERE
DATE=$(date -Iseconds)
if [ $# -eq 1 ]; then
    if [ ! -z "$(git status -s)" ]; then
        echo "Pushing to GitHub... "
        git add -A
        git commit -m $DATE
        git push
    else
        echo "No changes in repo"
    fi
fi
echo $DIVIDER
echo "Completed on $DATE."
