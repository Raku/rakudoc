use v6.d;

use Test;

use P6doc;
use P6doc::Utils;
use P6doc::Index;

use Perl6::Documentable;


###
### Remember to set env P6DOC_TEST to successfully run tests!
###

plan 3;

subtest 'Search Type: \'Array\'', {
    # NOTE: Hardcoding 'Type' subfolder here should be avoided in the future
    # an exported variable from Perl6::Documentable should be used instead.
    my @doc-dirs = get-doc-locations() X~ 'Type';
    my IO::Path @pod-paths;
    my Perl6::Documentable @documentables;
    my Perl6::Documentable @search-results;

    for @doc-dirs -> $folder {
        @pod-paths.append: find-type-files('Array', $folder);
    }

    @documentables = process-type-pod-files(@pod-paths);
    @search-results = type-search('Array',
                                  @documentables);

    # Check if we received the desired Documentable object
    is @search-results.first.name eq 'Array', True;
}

subtest 'Search Type & routine: \'Map.new\'', {
    # NOTE: Hardcoding 'Type' subfolder here should be avoided in the future
    my @doc-dirs = get-doc-locations() X~ 'Type';
    my IO::Path @pod-paths;
    my Perl6::Documentable @documentables;
    my Perl6::Documentable @search-results;

    for @doc-dirs -> $folder {
        @pod-paths.append: find-type-files('Map', $folder);
    }

    @documentables = process-type-pod-files(@pod-paths);
    @search-results = type-search('Map',
                                  :routine('new'),
                                  @documentables);

    # Check if we received the desired Documentable object
    is @search-results.first.name eq 'new', True;
}


subtest 'Build routine index', {
    my %routine-index = create-routine-index([get-doc-locations()]);

    # Check if the index contains routines from the test-docs
    ok %routine-index{'new'};
    ok %routine-index{'abs'};
    ok %routine-index{'exit'};

    nok %routine-index{'hfdusfdhasdhfj'};
}
