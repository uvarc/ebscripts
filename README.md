# ebscripts
UVARC easyblocks and easyconfigs

## Instructions

The hostname does not matter as long as you are on the cluster. In other words, you do not have to be on production/derp to sync the corresponding software stack.

Do not edit files in the subdirectories manually - they are meant to be a mirror.

The sync script makes some assumptions:
- Production hostname
- EB version
- Derp YYYYMM = production YYYYMM + 6 months
- Path to system python
If these change, `sync.sh` should be updated accordingly.

### Syncing the software stack
#### Manual
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

#### scrontab

We have enabled `scrontab` on derp. Run `scrontab -e` and append these lines:

```bash
DIR=/path/to/git/ebscripts
#SCRON -p standard
#SCRON -A hpc_build
#SCRON -t 1:0:0
#SCRON -J ebscripts
@daily cd $DIR && ./scron.sh
```

The job runs automatically at midnight every day.

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
    git commit -C main
    git push
    ```
