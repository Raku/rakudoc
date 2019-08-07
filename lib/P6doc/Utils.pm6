unit module P6doc::Utils;

our $test = %*ENV<P6DOC_TEST>;

our @sys-doc-locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;
our @test-doc-locations = [$*CWD.add("{$*SPEC.dir-sep}t{$*SPEC.dir-sep}testdata{$*SPEC.dir-sep}mini-doc{$*SPEC.dir-sep}test-doc{$*SPEC.dir-sep}")];

sub get-doc-locations() is export {
    if $test {
        return @test-doc-locations
    } else {
        return @sys-doc-locations
    }
}

sub search-paths() is export {
    #return (('.', |$*REPO.repo-chain())>>.Str X~ </doc/>).grep: *.IO.d;
    return (('.', |$*CWD)>>.Str X~ </t/testdata/mini-doc/test-doc/>).grep: *.IO.d;
}

sub findbin() returns IO::Path is export {
    $*PROGRAM.parent;
}
