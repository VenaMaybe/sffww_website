#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

if [[ $(id -un) != sffww || ${HOME:-} != /home/sffww || $# -ne 0 ]]; then
    echo 'Run without arguments as sffww with its normal home.' >&2
    exit 1
fi

exec 9>/home/sffww/.deploy-sffww.lock
flock -n 9 || { echo 'Another SFFWW deployment is running.' >&2; exit 1; }

cd /srv/sffww_website
git fetch origin main
# This checkout is disposable; edit locally and push, never edit on the VPS.
git reset --hard origin/main
commit=$(git rev-parse HEAD)

# Publish root-level pages/styles/images, never .git, workflows or operator files.
shopt -s nullglob
assets=( *.html *.css *.png )
test -s index.html
for asset in "${assets[@]}"; do
    test -s "$asset"
    test ! -L "$asset"
done
release=$(mktemp -d "/var/www/sffww/releases/${commit}.XXXXXXXX")
chmod 0755 "$release"
install -m 0644 "${assets[@]}" "$release/"

# Swap the complete website into place on the same filesystem.
# Prior releases remain available for manual rollback.
next_link="/var/www/sffww/.current-$(basename "$release")"
ln -s "$release" "$next_link"
mv -Tf "$next_link" /var/www/sffww/current
printf 'Published SFFWW commit %s at %s\n' "$commit" "$release"
