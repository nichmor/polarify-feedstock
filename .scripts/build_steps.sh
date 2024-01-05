#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

# -*- mode: jinja-shell -*-

set -xeuo pipefail
export FEEDSTOCK_ROOT="${FEEDSTOCK_ROOT:-/home/conda/feedstock_root}"
source ${FEEDSTOCK_ROOT}/.scripts/logging_utils.sh


( endgroup "Start Docker" ) 2> /dev/null

( startgroup "Configuring conda" ) 2> /dev/null

export PYTHONUNBUFFERED=1
export RECIPE_ROOT="${RECIPE_ROOT:-/home/conda/recipe_root}"
export CI_SUPPORT="${FEEDSTOCK_ROOT}/.ci_support"
export CONFIG_FILE="${CI_SUPPORT}/${CONFIG}.yaml"

cat >~/.condarc <<CONDARC

conda-build:
  root-dir: ${FEEDSTOCK_ROOT}/build_artifacts
pkgs_dirs:
  - ${FEEDSTOCK_ROOT}/build_artifacts/pkg_cache
  - /opt/conda/pkgs
solver: libmamba

CONDARC
export CONDA_LIBMAMBA_SOLVER_NO_CHANNELS_FROM_INSTALLED=1

mamba install --update-specs --yes --quiet --channel conda-forge/label/rattler-build_rc --channel conda-forge --strict-channel-priority \
    pip mamba rattler-build=0.6.2rc5 conda-forge-ci-setup=4
mamba update --update-specs --yes --quiet --channel conda-forge/label/rattler-build_rc --channel conda-forge --strict-channel-priority \
    pip mamba rattler-build=0.6.2rc5 conda-forge-ci-setup=4

# set up the condarc
setup_conda_rc "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"

source run_conda_forge_build_setup

# make the build number clobber
make_build_number "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"



( endgroup "Configuring conda" ) 2> /dev/null

if [[ -f "${FEEDSTOCK_ROOT}/LICENSE.txt" ]]; then
  cp "${FEEDSTOCK_ROOT}/LICENSE.txt" "${RECIPE_ROOT}/recipe-scripts-license.txt"
fi

if [[ "${BUILD_WITH_CONDA_DEBUG:-0}" == 1 ]]; then
    if [[ "x${BUILD_OUTPUT_ID:-}" != "x" ]]; then
        EXTRA_CB_OPTIONS="${EXTRA_CB_OPTIONS:-} --output-id ${BUILD_OUTPUT_ID}"
    fi
    conda debug "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml"

    # Drop into an interactive shell
    /bin/bash
else
    
    ## rattler-build build -r recipe -m .ci_support/linux_64_.yaml
    rattler-build build -r "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml"
        # --suppress-variables ${EXTRA_CB_OPTIONS:-} \
        # --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml" \
        # --extra-meta flow_run_id="${flow_run_id:-}" remote_url="${remote_url:-}" sha="${sha:-}" \
        # --extra-meta conda-forge-build="rattler-build"
    
    ( startgroup "Uploading packages" ) 2> /dev/null

    export ANACONDA_API_KEY=$STAGING_BINSTAR_TOKEN

    if [[ "${UPLOAD_PACKAGES}" != "False" ]] && [[ "${IS_PR_BUILD}" == "False" ]]; then
        rattler-build upload -vvv anaconda --owner cf-staging $(find build_artifacts -type f \( -name "*.conda" -o -name "*.tar.bz2" \)) --channel polarify-rattler-build_dev
    fi

    ( endgroup "Uploading packages" ) 2> /dev/null
fi

( startgroup "Final checks" ) 2> /dev/null

touch "${FEEDSTOCK_ROOT}/build_artifacts/conda-forge-build-done-${CONFIG}"