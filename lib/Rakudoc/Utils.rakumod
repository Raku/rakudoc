unit module Rakudoc::Utils;

# One might want to use a constant for $rakudoc-test-mode, however with the way
# precompilation works this would prevent from quickly switching it on and off.
# Once set to True/False, it will remain so until another precompilation is
# triggered. So for now it's just a regular scalar
our $rakudoc-test-mode = %*ENV<RAKUDOC_TEST> // %*ENV<P6DOC_TEST>;

my @sys-doc-locations = $*REPO.repo-chain.map(*.Str.IO.add: 'doc').grep(*.d);
my @test-doc-locations = [$*CWD.add('t').add('testdata')
                                .add('mini-doc').add('test-doc')];

sub get-doc-locations() is export {
    if $rakudoc-test-mode {
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
