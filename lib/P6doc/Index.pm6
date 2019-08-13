# TODO: Replace with Path::Finder
#use File::Find;
use JSON::Fast;

unit module P6doc::Index;

use P6doc::Utils;

constant $index-filename = 'p6doc-index.json';

constant @index-path-candidates = Array[IO::Path](
    ("$*HOME/.perl6").IO.add($index-filename),
    $*CWD.add($index-filename)
);

sub get-index-path returns IO::Path {
    my IO::Path $index-path;

    for @index-path-candidates -> $p {
        if $p.e {
            $index-path = $p;
            last;
        }
    }

    unless $index-path.defined and $index-path.e {
        fail "Unable to find p6doc-index.json at: {@index-path-candidates.join(', ')}"
    }

    return $index-path;
}

constant INDEX is export = @index-path-candidates.first;
