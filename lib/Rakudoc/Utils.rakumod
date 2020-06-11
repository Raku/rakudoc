unit module Rakudoc::Utils;

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
