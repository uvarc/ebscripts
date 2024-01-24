#!/bin/bash -e
HERE=$(pwd)
DIVIDER="--------------------------------------------------"

function sync() {
    cd $SOFTWAREDIR/$1
    find . -mindepth $2 -maxdepth $2 -type f \( -name *.eb -or -name *.patch \) \
        -exec rsync -qav {} $HERE/easyconfigs \;  
}

module purge
export MODULEPATH=/apps/modulefiles:$MODULEPATH
ml easybuild/4.7.1 || {
    echo "Failed to load EasyBuild"
    exit 1
}

PYVER=$($EB_INSTALLPYTHON -V|awk '{print $2}') # e.g. 3.6.8
PYVER=${PYVER%.*}                              # e.g. 3.6
EASYBLOCKSDIR=$EBROOTEASYBUILD/lib/python${PYVER}/site-packages/easybuild/easyblocks/
SOFTWAREDIR=${EASYBUILD_INSTALLPATH}/${EASYBUILD_SUBDIR_SOFTWARE}

# check for valid REMOTEURL
if [[ "" == "$REMOTEURL" ]]; then
    echo "Remote repo not specified. Run this script inside a git repository, or specify repo with -r <REPO_URL>"
fi

# get url of remote repo; returns "" if current directory is not a git repo
REMOTEURL=$(git config --get remote.origin.url)
REMOTEBRANCH=main
REPONAME=$(basename $REMOTEURL)

# Configuration
echo $DIVIDER
echo "EasyBuild root: $EBROOTEASYBUILD"
echo "Remote Repo URL: $REMOTEURL"
echo "Installed easyconfigs and patches: $SOFTWAREDIR"
echo "Easyblocks: $EASYBLOCKSDIR"
echo $DIVIDER

# easyconfigs
echo "Syncing installed easyconfigs and patches..."
sync core       4
sync compiler   6
sync mpi        8
sync toolchains 4
sync container  6
echo "Done."
echo $DIVIDER

# Easyblocks
echo "Syncing easyblocks..."
rsync -qav --exclude __init__.py --exclude __pycache__ --exclude *.pyc --exclude *.pyo "$EASYBLOCKSDIR" $HERE/easyblocks

# Check repo in current dir and check status against remote HEAD
#REMOTEINFO=$(git remote show origin)
#echo -e "Checking repo status: local vs $REMOTEURL"
#echo -e "$REMOTEINFO\n"
#
## Check the relationship between local HEAD commit and tracked remote HEAD commit to ensure nothing has changed since cloning event 
## define upstream branch; use currently configured branch in local repo by default
#UPSTREAM='@{u}'
## get local HEAD commit rev
#LOCAL=$(git rev-parse @{0})
## get tracked remote HEAD commit rev
#REMOTE=$(git rev-parse "$UPSTREAM")
## get last commit shared between local and tracked remote
#BASE=$(git merge-base @{0} "$UPSTREAM")
#if [ $LOCAL = $REMOTE ]; then
#    echo "Local and Remote HEAD commit are in sync."
#    git add -A
#    status=$(git status -s)
#    echo ${status}
#    # parse names of new, renamed, modified, and deleted easyconfig files
#    nfiles=( $(git status -s | grep "A" | grep -e "\.eb" | awk '{print $NF}') )
#    new_files=${nfiles[@]##*/} # trim
#    rfiles=( $(git status -s | grep "R" | grep -e "\.eb" | awk '{print $NF}') )
#    renamed_files=${rfiles[@]##*/} # trim
#    mfiles=( $(git status -s | grep "M" | grep -e "\.eb" | awk '{print $NF}') ) 
#    mod_files=${mfiles[@]##*/} # trim   
#    dfiles=( $(git status -s | grep "D" | grep -e "\.eb" | awk '{print $NF}') ) 
#    del_files=${dfiles[@]##*/} # trim
#    # get all other non .eb files    
#    ofiles=( $(git status -s | grep -v -e "\.eb" | awk '{print $NF}') )                  
#    other_files=${ofiles[@]##*/} # trim
#    msg=${COMMITMSG:-"SNAPSHOT-- NEW: ${new_files[@]}, RENAMED: ${renamed_files[@]}, MODIFIED: ${mod_files[@]}, DELETED: ${del_files[@]}, OTHERS: ${other_files[@]}"}
#    git commit -m "$msg" || :
#    git push
#    rm -rf $TMPCLONEDIR 
#elif [ $LOCAL = $BASE ]; then
#    echo "Remote banch is ahead of local branch. Need to pull from remote repo."
#elif [ $REMOTE = $BASE ]; then
#    echo "Local branch is ahead of remote branch. This needs to be resolved first"
#else
#    echo "Local and remote branches have diverged. Cannot autosync."
#fi
