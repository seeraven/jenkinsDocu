#!/bin/bash -eu
#
# Perform backup of Jenkins
# -------------------------
#
# This script is intended to be customized and started as root as
# a cron job. An example crontab entry would be:
#
#  # Perform backup every day at 3 AM
#  MAILTO=admin@jenkins.local.net
#  0 3 * * * /root/jenkinsHelpers/backup.sh
#
# Before using this script, adjust the settings below!
#
# The encrypted backup can be extracted using the following command:
#   openssl enc -d -aes256 -salt -iter 100 -pass pass:<password> -in backup.tgz.enc -out - | tar xfz -
#


# -----------------------------------------------------------------------------
# SETTINGS
# -----------------------------------------------------------------------------

# If using a docker container, specify the name of the container to stop and
# start. If left empty, it is assumed Jenkins is started via systemd.
JENKINS_DOCKER_CONTAINER=

# Home directory of jenkins
JENKINS_HOME=/var/lib/jenkins

# Jenkins URL (without trailing slash)
JENKINS_URL=http://localhost:8080

# Password of the encrypted tar archive
export BACKUP_PASSWORD=jenkinsBackup

# Administrator username for Jenkins CLI
export JENKINS_USER_ID=admin

# Administrator password or API token
export JENKINS_API_TOKEN=passwordOrToken

# Shutdown message
SHUTDOWN_MESSAGE="Jenkins is shutting down for backup."

# Interval of Jenkins CLI command finished-safe-quietdown
FINISHED_SAFE_QUIETDOWN_CHECK_INTERVAL=10s

# Minimum number of successfull finished-safe-quietdown commands before
# assuming Jenkins is really finished and can be shut down for backup.
NUM_FINISHED_SAFE_QUIETDOWN_CALLS=3

# Maximum attempts to wait for finished-safe-quietdown. If not finished within
# time, the backup attempt is aborted and an error message is printed.
FINISHED_SAFE_QUIETDOWN_MAX_ATTEMPTS=360

# Backup filename
BACKUP_ARCHIVE_FILENAME=backup_jenkins_$(date +%Y%m%d).tar.gz.enc

# Local target (leave empty if you don't want to store backups locally)
LOCAL_TARGET=/mnt/jenkinsBackups

# Remote target (leave empty if you don't want to store backups remotely)
REMOTE_TARGET=myuser@remote.machine:jenkinsBackups/


# -----------------------------------------------------------------------------
# INTERNAL SETTINGS
# -----------------------------------------------------------------------------

TEMPDIR=$(mktemp -d)
JENKINS_CLI_JAR_URL=${JENKINS_URL}/jnlpJars/jenkins-cli.jar
JENKINS_CLI_JAR=${TEMPDIR}/jenkins-cli.jar


# -----------------------------------------------------------------------------
# INTERNAL FUNCTIONS
# -----------------------------------------------------------------------------

function jenkins_is_active() {
    if [ -z "${JENKINS_DOCKER_CONTAINER}" ]; then
        systemctl is-active --quiet jenkins.service
    else
        docker container inspect ${JENKINS_DOCKER_CONTAINER} &>/dev/null
    fi
}

function jenkins_stop() {
    if [ -z "${JENKINS_DOCKER_CONTAINER}" ]; then
        systemctl stop --quiet jenkins.service
    else
        docker stop ${JENKINS_DOCKER_CONTAINER}
    fi
}

function jenkins_start() {
    if [ -z "${JENKINS_DOCKER_CONTAINER}" ]; then
        systemctl start --quiet jenkins.service
    else
        docker start ${JENKINS_DOCKER_CONTAINER}
    fi
}

function jenkins_cli() {
    java -jar ${JENKINS_CLI_JAR} -s ${JENKINS_URL}/ -webSocket "$@"
}

function jenkins_finished() {
    jenkins_cli finished-safe-quiet-down
}


# -----------------------------------------------------------------------------
# SAFE SHUTDOWN OF JENKINS
# -----------------------------------------------------------------------------

if jenkins_is_active; then
    wget --quiet -O ${JENKINS_CLI_JAR} ${JENKINS_CLI_JAR_URL}
    jenkins_cli safe-quiet-down --message "${SHUTDOWN_MESSAGE}" || true

    NUM_ATTEMPTS=1
    NUM_FINISHED=0
    if jenkins_finished; then
        NUM_FINISHED=1
    fi
    while [[ ${NUM_FINISHED} -lt ${NUM_FINISHED_SAFE_QUIETDOWN_CALLS} ]] && [[ ${NUM_ATTEMPTS} -lt ${FINISHED_SAFE_QUIETDOWN_MAX_ATTEMPTS} ]]; do
        sleep ${FINISHED_SAFE_QUIETDOWN_CHECK_INTERVAL}
        let NUM_ATTEMPTS=${NUM_ATTEMPTS}+1
        if jenkins_finished; then
            let NUM_FINISHED=${NUM_FINISHED}+1
        else
            NUM_FINISHED=0
        fi
    done

    if [[ ${NUM_FINISHED} -lt ${NUM_FINISHED_SAFE_QUIETDOWN_CALLS} ]]; then
        jenkins_cli cancel-safe-quiet-down
        cat <<EOF
ERROR: safe-quiet-down not finished within time!
       Performed ${NUM_ATTEMPTS} tests at an interval of ${FINISHED_SAFE_QUIETDOWN_CHECK_INTERVAL},
       but only the last ${NUM_FINISHED} tests were successfull (required ${NUM_FINISHED_SAFE_QUIETDOWN_CALLS})

Aborting backup!
EOF
        rm -rf ${TEMPDIR}
        exit 1
    fi

    jenkins_stop
fi


# -----------------------------------------------------------------------------
# BACKUP
# -----------------------------------------------------------------------------
set -o pipefail

if [ -z "${LOCAL_TARGET}" ]; then
    LOCAL_TARGET=${TEMPDIR}
fi

if ! tar -c -f - -z --exclude=${JENKINS_HOME}/workspace ${JENKINS_HOME} | openssl enc -e -aes256 -salt -iter 100 -pass env:BACKUP_PASSWORD -out ${LOCAL_TARGET}/${BACKUP_ARCHIVE_FILENAME}; then
    cat <<EOF
ERROR: Can't create encrypted tar archive!

Aborting backup!
EOF
    rm -rf ${TEMPDIR} ${LOCAL_TARGET}/${BACKUP_ARCHIVE_FILENAME}
    jenkins_start
    exit 1
fi


# -----------------------------------------------------------------------------
# START JENKINS AGAIN
# -----------------------------------------------------------------------------
jenkins_start


# -----------------------------------------------------------------------------
# COPY BACKUP
# -----------------------------------------------------------------------------
if [ -n "${REMOTE_TARGET}" ]; then
    rsync -av ${LOCAL_TARGET}/${BACKUP_ARCHIVE_FILENAME} ${REMOTE_TARGET}
fi


# -----------------------------------------------------------------------------
# CLEANUP
# -----------------------------------------------------------------------------
rm -rf ${TEMPDIR}
exit 0
