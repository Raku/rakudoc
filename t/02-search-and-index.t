use v6.d;

use Test;

use Rakudoc;
use Rakudoc::Utils;
use Rakudoc::Index;

use Documentable;


###
### Remember to set env RAKUDOC_TEST to successfully run tests!
###

plan 3;

subtest 'Search Type: \'Array\'', {
    # NOTE: Hardcoding 'Type' subfolder here should be avoided in the future
    # an exported variable from Documentable should be used instead.
    my @doc-dirs = get-doc-locations.map: *.add('Type');
    my IO::Path @pod-paths;
    my Documentable @documentables;
    my Documentable @search-results;

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
    my @doc-dirs = get-doc-locations.map: *.add('Type');
    my IO::Path @pod-paths;
    my Documentable @documentables;
    my Documentable @search-results;

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
    my %index = create-index([get-doc-locations()]);

    # Check if the index contains routines from the test-docs
    ok %index{'new'};
    ok %index{'abs'};
    ok %index{'exit'};

    nok %index{'hfdusfdhasdhfj'};
}
