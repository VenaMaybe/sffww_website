#!/usr/bin/env bash
set -Eeuo pipefail
if [[ ${RENEWED_LINEAGE:-} == /etc/letsencrypt/live/sffww.com ]]; then
    /usr/sbin/apache2ctl configtest
    /usr/bin/systemctl reload apache2
fi
