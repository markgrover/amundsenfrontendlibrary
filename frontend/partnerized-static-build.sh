#!/bin/bash
#######################################
# This script can be run from either
# /amundsenfrontend-private or /amundsenfrontend-private/scripts
#######################################


#######################################
# Validate status code. If status is not 0, it will exit with status code
#######################################
validate_status_code() {
    status_code=$?
    if [[ ${status_code} -ne 0 ]]; then
        echo "Failed bash command: $1"
        exit ${status_code}
    fi
}

print_usage() {
    echo "partnerized-static-build.sh [Options]"
    echo "    Combines static resources from amundsenfrontendlibrary and amundsenfrontend-private by copying all"
    echo "    files into a temp directory, installing, building, and deploying from there."
    echo ""
    echo "Options:"
    echo "    --base: Skips partnerization step and builds the base version"
    echo "    --dev-build: Runs 'npm run dev-build' instead of 'npm run build'"
    echo "    --skip-npm-install: Preserves node_modules from a previous installation"
    echo "    --quick: Build that utilizes --dev-build and --skip-npm-install options"
}

dev_mode=false
partnerize_build=true
skip_npm=false

while [[ -n "$1" ]]; do
    case "$1" in
    --base) partnerize_build=false ;;
    --dev-build) dev_mode=true ;;
    --skip-npm-install) skip_npm=true ;;
    --quick)
        dev_mode=true
        skip_npm=true ;;
    -h|--help)
        print_usage
        exit 0 ;;
    *)
        print_usage
        exit 1 ;;
    esac
    shift
done

if [[ $PWD = */scripts ]]; then
    destination="../upstream/amundsen_application/.src-custom"
    upstream_static="../upstream/amundsen_application/static"
    private_static="../static"
else
    destination="upstream/amundsen_application/.src-custom"
    upstream_static="upstream/amundsen_application/static"
    private_static="static"
fi

if [[ "$skip_npm" = true ]]; then
    echo "Moving $destination/node_modules to temp_node_modules for later use"
    mv ${destination}/static/node_modules temp_node_modules

    echo "Cleaning previous build in: ${destination}/"
    rm -rf ${destination}/

    echo "Moving temp_node_modules back to ${destination}/node_modules"
    mkdir ${destination}
    mkdir ${destination}/static
    mv temp_node_modules ${destination}/static/node_modules
else
    echo "Cleaning previous build in: ${destination}/"
    rm -rf ${destination}
fi


echo "Copying base static files from ${upstream_static} to ${destination}"
rsync -av ${upstream_static} ${destination} --exclude node_modules --exclude dist

if [[ "$partnerize_build" = true ]]; then
  echo "Copying partnerized static files from ${private_static} to ${destination}"
  rsync -av ${private_static} ${destination}
fi


echo "Installing Node modules in ${destination}/static"
pushd ${destination}/static

    if [[ "$skip_npm" = false ]]; then
        npm install
        validate_status_code "npm install"
    fi

    if [[ "$dev_mode" = true ]]; then
        echo "Running Webpack Build in Development Mode"
        npm run dev-build
        validate_status_code "npm run dev-build"
    else
        echo "Running Webpack Build in Production Mode"
        npm run build
        validate_status_code "npm run build"
    fi
popd