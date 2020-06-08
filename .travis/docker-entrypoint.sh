#! /bin/sh

set -x

# Update docker instance
apk update
apk upgrade

# Report status
raku --version
which zef
zef --installed list

# Install module dependencies
zef install . --deps-only --force

set -e

RAKUDOC_TEST=1 zef test .
zef install --/test .
