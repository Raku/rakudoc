unit module P6doc::Utils;

constant @doc-locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;

sub findbin() returns IO::Path is export {
    $*PROGRAM.parent;
}
