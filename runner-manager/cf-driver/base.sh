#!/usr/bin/env bash
#
# This is sourced by prepare, run, and cleanup

# This name will be long. Hopefully not too long!
CONTAINER_ID="glrw-r$CUSTOM_ENV_CI_RUNNER_ID-p$CUSTOM_ENV_CI_PROJECT_ID-c$CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID-j$CUSTOM_ENV_CI_JOB_ID"

# Set RUNNER_DEBUG if missing and set through CI settings
if [ "${CUSTOM_ENV_RUNNER_DEBUG:-}" == "true" ]; then
    RUNNER_DEBUG="true"
fi

# Set xtrace, log commands to aid debugging
if [ "$RUNNER_DEBUG" == "true" ]; then
    debug_allowed="false"

    for email in $RUNNER_DEBUG_USERS; do
        if [ "$email" == "${CUSTOM_ENV_GITLAB_USER_EMAIL}" ]; then
            debug_allowed="true"
            break
        fi
    done

    if [ $debug_allowed == "true" ]; then
        set -x
    else
        RUNNER_DEBUG="false"
    fi
fi

# Set a fallback if not set but complain
if [ -z "$DEFAULT_JOB_IMAGE" ]; then
    DEFAULT_JOB_IMAGE="ubuntu:24.04"
    echo "WARNING: DEFAULT_JOB_IMAGE not set! Falling back to ${DEFAULT_JOB_IMAGE}" 1>&2
fi

# Complain if no Docker Hub credentials so we aren't bad neighbors
if [ -z "$DOCKER_HUB_USER" ] || [ -z "$DOCKER_HUB_TOKEN" ]; then
    echo "WARNING: Docker Hub credentials not set! Falling back to public access which could result in rate limiting." 1>&2
fi

# Use a custom image if provided, else fallback to configured default
CUSTOM_ENV_CI_JOB_IMAGE="${CUSTOM_ENV_CI_JOB_IMAGE:=$DEFAULT_JOB_IMAGE}"

cf_ssh() {
    container_id="$1"
    command="$2"
    app_guid=$(cf app "$container_id" --guid)
    SSHPASS=$(cf ssh-code) sshpass -e ssh -p 2222 -T "cf:$app_guid/0@$CG_SSH_HOST" "$command"
}

cf_scpr() {
    container_id="$1"
    src_dir="$2"
    dst_dir="${3:-}"
    app_guid=$(cf app "$container_id" --guid)
    SSHPASS=$(cf ssh-code) sshpass -e scp -r -P 2222 -o User="cf:$app_guid/0" "$src_dir" "$CG_SSH_HOST:$dst_dir"
}
