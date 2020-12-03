#!/bin/bash
log="logger -t update.sh -s "

function update(){
    sudo killall -15 raspimjpeg
    sudo killall -15 python3
    git stash
    git merge
    git checkout stash@'{0}' -- config.json hardware.json
    # TODO we need to change this to drop stash@{1} if changes made to the flow are to be restored by the user
    git stash drop
    sudo systemctl restart nodered.service
}

function special(){
    if [[ -f "/etc/systemd/system/usb-mount@.service" ]]; then
        sudo rm /etc/systemd/system/usb-mount@.service
    fi
    if [[ -f "/etc/udev/rules.d/99-local.rules" ]]; then
        sudo rm /etc/udev/rules.d/99-local.rules
    fi
    if ! [ -x "$(hash thumbsup &> /dev/null)" ] ; then
        ${log} "thumbsup is not installed, installing now"
        sudo chown -R pi:pi /usr/lib/node_modules/
        if npm install -g thumbsup; then
            ${log} "Error when installing thumbsup"
        fi
        sudo chown -R root:root /usr/lib/node_modules/
    fi
}

${log} "Updating the main repository"
cd /home/pi/PlanktonScope || { echo "/home/pi/PlanktonScope does not exist"; exit 1; }

# TODO We need to add here a way to load the latest version of this script and execute it again
remote=$(git ls-remote -h origin master | awk '{print $1}')
local=$(git rev-parse HEAD)
${log} "Local : $local - Remote: $remote"
if [[ "$local" == "$remote" ]]; then
    ${log} "nothing to do!"
else
    git fetch
    UPDATE=$(git diff --numstat origin/master scripts/bash/update.sh | awk '/update.sh/ {print $NF}')
    if [[ -n "${UPDATE}" ]]; then
        # Update the file and restart the script
        git checkout origin/master scripts/bash/update.sh
        exec scripts/bash/update.sh
    fi
    special
    update
    ${log} "Done!"
fi