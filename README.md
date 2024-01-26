# ebscripts
UVARC easyblocks and easyconfigs

## Instructions

### Syncing the software stack
Production:
1. Make sure you're on the `main` branch
1. Run
    ```
    ./sync.sh p
    ```

Derp:
1. Make sure you're on the `derp` branch
1. Run
    ```
    ./sync.sh d
    ```

Add a second argument for dry run.

### Updating the sync script
1. Make changes and push to the `main` branch:
    ```
    git checkout main
    # edit sync.sh
    git add sync.sh
    git commit -m "..."
    git push
    ```
1. Sync to `derp` branch:
    ```
    git checkout derp
    git checkout main -- sync.sh
    git add sync.sh
    git commit -m "sync sync.sh"
    git push
    ```
