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

list_repo_docs () {
    "${1:-raku}" -e \
        '.put for $*REPO.repo-chain.map(*.Str.IO).grep(*.d)>>.add("doc")' | \
            while read dir; do
                if [ -d "$dir" ]; then
                    (cd "$dir" && \
                        find . -name .precomp -prune -o -type f -print | \
                        sed 's/^/  - /'
                    )
                else echo "$dir (Not found)";
                fi;
            done
}

# Install real docs for testing, but don't fail if p6doc won't install
if zef install p6doc --/test; then
    # Attempt running tests against the real docs; they probably pass,
    # but don't fail the build if they don't
    prove6 -v || true

    # Ensure basic usage in a real install environment, with a doc that
    # does NOT exist in testdata/ but surely will be in the full docs
    if rakudoc -n Order; then :; else
        which raku
        list_repo_docs raku
        false
    fi
fi
