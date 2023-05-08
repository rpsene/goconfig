#!/bin/bash

: '
Copyright (C) 2018, 2023

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
        * Hiro Miyamoto <miyamotoh@fuji.waseda.jp>

    This script installs and configure a GO development environment on Linux
    running on x86_64, AMD64, ppc64le, s390x and aarch64.
'

# Define the list of supported architectures
SUPPORTED_ARCHS=(arm64 amd64 x86_64 ppc64le s390x)

function get_content {
    local content
    local url="https://golang.org/dl/"

    echo "Fetching content from ${url}..."
    content=$(wget "${url}" -q -O -)

    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch content from ${url}"
        return 1
    fi

    # Returns the raw content
    echo "$content"
}

function get_all_versions () {
    if [ $# -eq 0 ]
    then
        echo "No architecture set."
        return
    fi

    local content
    content=$(get_content)

    # Extract URLs from the raw content, filtering for desired architecture, Linux, tar.gz files, and non-beta versions
    # Remove prefix and suffix to obtain only the version number, sort and remove duplicates
    versions=( "$(echo "$content" | grep -Eoi '<a [^>]+>' | \
    grep -Eo 'href="[^\"]+"' | grep "$1" | grep linux | grep "tar.gz" | \
    awk '!/beta/ && !/rc/' | sed -e 's/^href="//' -e 's/"$//' | \
    awk -F'/' '{print $3}' | sort -t. -k 1,1n -k 2,2n -k 3,3n | \
    uniq | sed -e 's/^go//' -e "s/.linux-$1.tar.gz//")" )

    # Return an array with all supported versions
    echo "${versions[@]}"
}

function download_go () {
    if [ $# -ne 2 ]; then
        echo "Error: Both the GO version and the architecture are required."
        return
    fi

    local go_version="$1"
    local arch="$2"
    local go_file="go${go_version}.linux-${arch}.tar.gz"
    local download_url="https://dl.google.com/go/${go_file}"

    echo "Downloading Go ${go_version} for ${arch} architecture..."
    if wget "${download_url}" &&
       tar -C /usr/local -xzf "${go_file}" &&
       rm -f "./${go_file}"; then
        echo "Go ${go_version} successfully installed."
    else
        echo "Error: Failed to download and install Go ${go_version} for ${arch} architecture."
        return 1
    fi
}

function create_go_env () {
    # go-workspace is a directory hierarchy for your GO code
    # src contains Go source files,
    # pkg contains package objects, and
    # bin contains executable commands
    local workspace_dirs=("bin" "src" "pkg")
    local go_workspace="$HOME/go-workspace"

    for dir in "${workspace_dirs[@]}"; do
        mkdir -p "${go_workspace}/${dir}"
    done

    PATH="/usr/local/go/bin:$PATH"
    export PATH
    GOPATH="$go_workspace"
    export GOPATH
    PATH="$(go env GOPATH)/bin:$PATH"
    export PATH

    echo "Go environment successfully set up:"
    go env
}


function download_go_dep () {
    echo "Downloading Go Dep..."
    if curl -fsSL https://raw.githubusercontent.com/golang/dep/master/install.sh | sh; then
        echo "Go Dep successfully installed."
    else
        echo "Error: Failed to download and install Go Dep."
        return 1
    fi
}

function run_sample () {
    # Create the sample hello directory and file
    mkdir -p "$GOPATH/src/hello"
    cat > "$GOPATH/src/hello/hello.go" <<- EOM
package main

import "fmt"

func main() {
    fmt.Printf("hello, your GO setup works!\n")
}
EOM

    # Build and run the sample program
    pushd "$GOPATH/src/hello" >/dev/null || return
    go build
    ./hello

    # Clean up the sample directory
    popd >/dev/null || return
    rm -rf "$GOPATH/src/hello"
}


function help(){
	echo "Usage : source $0 [install, install x,y.z, remove, env, versions]"
        echo "
		install: install GO
		install x.y.z: install a specific version of GO
		remove: remove GO (delete it from /usr/local)
		env: configure the environment to start using GO
		versions: list of GO versions that can be installed
                "
}

# The main function which controls the script
function run () {
    # Get the architecture on which this script is running
    ARCH=$(uname -m)

    # Replace x86_64 with amd64 and aarch64 with arm64, as used in Go naming conventions
    case "$ARCH" in
        "x86_64") ARCH="amd64" ;;
        "aarch64") ARCH="arm64" ;;
    esac

    # Check if the platform on which the script is executed is supported
    if ! [[ "${SUPPORTED_ARCHS[*]}" =~ "$ARCH" ]]; then
        echo "ERROR: Supported architectures are:" "${SUPPORTED_ARCHS[@]}"
        return
    else
        echo "Supported Architecture :)"
    fi

    # Check if at least one parameter is set
    if [ "$#" -lt 1 ]; then
        help
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        return
    fi

    case "$1" in
        "install")
            # Get all available versions
            all=( $(get_all_versions $ARCH) )

            # Pick which version to install
            if [ -n "$2" ]; then
                for v in "${all[@]}"; do
                    [ "$2" == "$v" ] && version2install=$v
                done
            fi
            [ -z "$version2install" ] && version2install=${all[${#all[@]}-1]} # defaults to the latest available

            # Download the latest version
            download_go "$version2install" $ARCH
            # Create the env for using GO
            create_go_env
            # Download Go Dep
            download_go_dep
            # Run Sample
            #run_sample
            ;;
        "remove")
            rm -rf /usr/local/go
            ;;
        "env")
            # Create the env for using GO
            create_go_env
            # Run Sample
            #run_sample
            ;;
        "versions")
            all=( $(get_all_versions $ARCH) )
            echo "${all[*]}"
            ;;
        *)
            help
            ;;
    esac
}

### Main Execution ###
run "$@"
