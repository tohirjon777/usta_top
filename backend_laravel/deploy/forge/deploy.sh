#!/bin/bash

set -euo pipefail

cd "$FORGE_SITE_PATH/backend_laravel"

$FORGE_PHP artisan down || true

composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

$FORGE_PHP artisan migrate --force
$FORGE_PHP artisan ustatop:bootstrap-storage
$FORGE_PHP artisan ustatop:doctor

$FORGE_PHP artisan optimize:clear
$FORGE_PHP artisan config:cache
$FORGE_PHP artisan route:cache
$FORGE_PHP artisan view:cache

$FORGE_PHP artisan up || true
