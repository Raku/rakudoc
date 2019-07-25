use v6.d;
use Test;

use P6doc;
use P6doc::Utils;
use P6doc::Index;

use JSON::Fast;

###
###
###

plan 1;

subtest 'finding test-doc folder', {
    ok (get-doc-locations(:test) >= 1);

    # Check that every Path `get-doc-locations` returns
    # is actually a directory
    my Bool @directory-check;
    for get-doc-locations(:test) -> $p {
        @directory-check.push: $p.d;
    }
    ok [and] @directory-check;
}
