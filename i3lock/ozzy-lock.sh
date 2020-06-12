#!/bin/bash
# Don't forget to chmod +x this file

# Dependencies:
# imagemagick
# i3lock

TIME_LOG=~/.timetrack/time.log
IMAGE_ORIG=~/.config/i3lock/i3lock.jpeg
IMAGE_PNG=~/.config/i3lock/i3lock.png
IMAGE_WIDTH=3840
IMAGE_HEIGHT=1200
BACKGROUND=000000

function logTime {
	CURRENT_TIME=`date`
    echo "$1, ${CURRENT_TIME}" >> $TIME_LOG
}

function prepareImageLock {
    #Allow param 1 as true to force image
    if [ $1 ] || [ ! -f $IMAGE_PNG ]; then
        wget https://picsum.photos/$IMAGE_WIDTH/$IMAGE_HEIGHT\?random\&blur -O $IMAGE_ORIG
        convert $IMAGE_ORIG $IMAGE_PNG
    fi
}

# Image doesn't exist / first time running, block, fetch image.
prepareImageLock;

#Screen is about to be locked. Log time.
logTime "Locked";

#Lock screen
i3lock -c $BACKGROUND -i $IMAGE_PNG -n;

#Screen was unlocked. Log time.
logTime "Unlocked";

#Fetch new image for next lock
prepareImageLock true;