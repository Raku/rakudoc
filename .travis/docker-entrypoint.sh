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
zef install . --deps-only --force-test

set -e

RAKUDOC_TEST=1 zef test .
zef install --/test .

# Install real docs for testing, but don't fail if p6doc won't install
zef install p6doc --/test && rakudoc -n IO::Spec || true
