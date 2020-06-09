unit module Rakudoc::Index;

constant $index-filename = 'rakudoc-index.json';

my IO::Path @index-candidates = map *.add($index-filename),
    %*ENV<XDG_CACHE_HOME>.?IO.add('raku') // Empty,
    $*HOME.add('.raku'),
    $*HOME.add('.perl6'),
    $*CWD;
    ;

sub index-path() returns IO::Path is export {
    state $ = @index-candidates.first(*.f) // @index-candidates.first;
}
