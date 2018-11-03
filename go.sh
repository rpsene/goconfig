#!/bin/bash

: '
Copyright (C) 2018 Rafael Peria de Sene
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
    Contributors:
        * Rafael Sene <rpsene@gmail.com>

    This script installs and configure a GO development environment on Linux
    running on x86_64, AMD64, ppc64le and s390x.
'

# Define the list of supported architectures
SUPPORTED_ARCHS=(amd64 x86_64 ppc64le s390x)

# Downloads the raw content of Go download page
function get_content { 
    local content
    content=$(wget https://golang.org/dl/ -q -O -)
    # Returns the raw content
    echo "$content"
}

# Filter the raw data collected from Go download page and
# returns an array with all supported versions for a
# given a supported architecture
function get_all_versions () {
    if [ $# -eq 0 ]
    then
        echo "No architecture set."
        return
    fi

    local content
    content=$(get_content)

    # From the raw content, gets all URLs that contains the desired
    # architecture, is Linux, is a tar file and is NOT a beta. Then
    # remove the prefix and the suffix to get only the version number
    versions=( "$(echo "$content" | grep -Eoi '<a [^>]+>' | \
    grep -Eo 'href="[^\"]+"' | grep "$1" | grep linux | grep "tar.gz" | \
    awk '!/beta/' | awk '!/rc/' | sed -e "s/^href=//" | tr -d '",' | \
    awk '{split($0, array, "/"); print array[5]}' | \
    sort -t. -k 1,1n -k 2,2n -k 3,3n | uniq | sed -e "s/^go//" | \
    sed -e "s/.linux-$1.tar.gz//")" )

    # Returns an array with all supported versions
    echo "${versions[@]}"
}

# Returns the lasted version of Go available for a given
# architecture
function download_go () { 
    if [ $# -eq 0 ]
    then
        echo "The GO version or the architecture is missing."
        return
    fi
    wget https://dl.google.com/go/go"$1".linux-"$2".tar.gz
    tar -C /usr/local -xzf go"$1".linux-"$2".tar.gz
}

# Creates the necessary infrastructure to get a fully functional
# environment for development and building using Go
function create_go_env () {

    # go-workspace is a directory hierarchy where you keep your GO code
    # src contains Go source files,
    # pkg contains package objects, and
    # bin contains executable commands
    if [ ! -d "$HOME"/go-workspace ]; then
        mkdir -p "$HOME"/go-workspace
    fi
    if [ ! -d "$HOME"/go-workspace/bin ]; then
        mkdir -p "$HOME"/go-workspace/bin
    fi
    if [ ! -d "$HOME"/go-workspace/src ]; then
        mkdir -p "$HOME"/go-workspace/src
    fi
    if [ ! -d "$HOME"/go-workspace/pkg ]; then
        mkdir -p "$HOME"/go-workspace/pkg
    fi

    PATH=$PATH:/usr/local/go/bin
    export PATH
    GOPATH=$HOME/go-workspace
    export GOPATH
    PATH=$PATH:$(go env GOPATH)/bin
    export PATH
    GOPATH=$(go env GOPATH)
    export GOPATH
}

function download_go_dep () {
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
}

# Executes a simple GO application to ensure the setup is correctly
# configured
function run_sample () {
    mkdir -p "$GOPATH"/src/hello

echo "
package main

import \"fmt\"

func main() {
    fmt.Printf(\"hello, your GO setup works!\\n\")
}" >> "$GOPATH"/src/hello/hello.go

    cd "$GOPATH"/src/hello || return
    go build
    ./hello
    cd "$GOPATH"/src || return
    rm -rf ./hello
}

# The main function which contains the control of the script
function run () {
    # Gets the architecture from where this is script is running
    ARCH=$(uname -m)

    # Replace x86_64 for amd64 because this is how Go named it :)
    if [ "$ARCH" = "x86_64" ]
    then
        ARCH="amd64"
    fi

    # Check wheter or not the platform where the platform where 
    # script is executed is supported
    case "${SUPPORTED_ARCHS[@]}" in  
        *"$ARCH"*) 
            echo "Supported Architecture :)";;
        *)
            echo "ERROR: Supported architectures are:" "${SUPPORTED_ARCHS[@]}"
            return
    esac

    # Check whether it was set at least two parameters
    if [ "$#" -eq 2 ]
    then
            echo "Usage : source $0 [install, remove, env]"
            echo "
                install: install go
                remove: remove go (delete it from /usr/local)
                env: configure the environment to start using go
                "
            return
    fi

    if [ "$1" = "install" ]
    then
        if [[ $EUID -ne 0 ]]; then
            echo "This script must be run as root"
            return
        fi
        # Get all available versions
        all=( $(get_all_versions $ARCH) )

        # Based on all collected versions, grab the latest one available
        lastest_version=${all[${#all[@]}-1]}

        # Download the lastest version
        download_go "$lastest_version" $ARCH

        # Create the env for using GO
        create_go_env

        # Download Go Dep
        download_go_dep
        
        # Run Sample
        run_sample
        
        return
    elif [ "$1" = "remove" ]
    then
        if [[ $EUID -ne 0 ]]; then
            echo "This script must be run as root"
            return
        fi
        rm -rf /usr/local/go

        return
    elif [ "$1" = "env" ]
    then
        # Create the env for using GO
        create_go_env

        # Run Sample
        run_sample

        return
    else
        echo "Please, select one of the supported options."
        echo "Usage : source $0 [install, remove, env]"
        echo "
             install: install go
             remove: remove go (delete it from /usr/local)
             env: configure the environment to start using go
            "
        return
    fi
}

### Main Execution ###
run "$@"
