#!/bin/bash

web_image="browser_image"
robot_image="robot_image"
android_image="budtmo/docker-android-x86-8.1"

network="network"
web_container_1="web_container_1"
web_container_2="web_container_2"
android_container="android_container"
robot_container="robot_container"

android_device="Samsung Galaxy S6"
apk_folder="/root/tmp/"
apk_name="hello_world.apk"

project_name=$(basename "$PWD")

RED=$(tput setaf 1;)
LIGHT_BLUE=$(tput setaf 4;)
LIGHT_GREEN=$(tput setaf 2;)
ORANGE=$(tput setaf 3;)
CYAN=$(tput setaf 6;)
NC=$(tput sgr0)

BOLD=$(tput bold)
NS=$(tput sgr0)

function build_images {
    echo "=============================================================================="
    echo "${BOLD}Building Docker images${NS}"

    # browser image
    echo "------------------------------------------------------------------------------"
    echo ${LIGHT_BLUE}$web_image${NC}
    docker build -q -f infra/web/dockerfile -t $web_image .

    # robot image
    echo "------------------------------------------------------------------------------"
    echo ${LIGHT_GREEN}$robot_image${NC}
    docker build -q -f infra/robot/dockerfile -t $robot_image .
}

function run_services {
    echo "=============================================================================="
    echo "${BOLD}Starting Docker services${NS}"

    # criar network
    echo "------------------------------------------------------------------------------"
    echo ${CYAN}$network${NC}
    docker network create $network

    # browser container 1
    echo "------------------------------------------------------------------------------"
    echo ${LIGHT_BLUE}$web_container_1${NC}
    docker run --net $network -p 8080:8080 -p 5900:5900 -d --rm --name $web_container_1 $web_image

    # browser container 2
    echo "------------------------------------------------------------------------------"
    echo ${LIGHT_BLUE}$web_container_2${NC}
    docker run --net $network -p 8081:8080 -p 5901:5900 -d --rm --name $web_container_2 $web_image

    # android container
    echo "------------------------------------------------------------------------------"
    echo ${ORANGE}$android_container${NC}
    docker run --net $network --privileged -v $PWD/infra/mobile:$apk_folder -d --rm -p 6080:6080 -p 4723:4723 -p 5554:5554 -p 5555:5555 -e DEVICE="$android_device" -e APPIUM=true -e APPIUM_HOST="127.0.0.1" -e APPIUM_PORT=4723 --name $android_container $android_image
    docker exec $android_container adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

    # robot container
    echo "------------------------------------------------------------------------------"
    echo ${LIGHT_GREEN}$robot_container${NC}
    docker run --net $network --link=$web_container_1 --link=$web_container_2 --link=$android_container -v $PWD:/$project_name -d --rm --name $robot_container $robot_image
    docker exec -it $robot_container robot --variable WEB_CONTAINER_1:$web_container_1 --variable WEB_CONTAINER_2:$web_container_2 --variable ANDROID_CONTAINER:$android_container --variable ANDROID_DEVICE:"$android_device" --variable APK_FOLDER:$apk_folder --variable APK_NAME:$apk_name --outputdir $project_name/logs -- $project_name/tests

    # open robot log after tests finish
    sensible-browser "file:///$PWD/logs/log.html" --no-sandbox > /dev/null 2>&1
}

function stop_services {
    echo "=============================================================================="
    echo "${BOLD}Stopping Docker services${NS}"
    docker stop $android_container
    docker stop $robot_container
    docker stop $web_container_1
    docker stop $web_container_2
    docker network rm $network
}

build_images

run_services && true | stop_services
