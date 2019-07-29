use P6doc;
use P6doc::Utils;
use P6doc::Index;

use Perl6::Documentable;

use JSON::Fast;

package P6doc::CMD {
    my $PROGRAM-NAME = "p6doc";

    sub USAGE() {
        say q:to/END/;
            p6doc is a tool for reading perl6 documentation.

            Options:

                [-d | --directory]      specify a doc directory
                [-h | --help]           print usage information
                [-r | --routine]        search by routine name

            Examples:

                p6doc Map
                p6doc Map.new
                p6doc -r=abs
                p6doc -d=./large-doc Map
                p6doc -d=./large-doc IO::Path
                p6doc -d=./large-doc -r=split

            Note:

                Usage of -r is not recommended right now!
            END
    }

    our proto MAIN(|) is export {
        {*}
    }

    multi MAIN(Bool :h(:$help)?) {
        USAGE();

        exit;
    }

    multi MAIN(Str $query, Str :d($dir)) {
        # TODO: This is currently a list, while
        # type search only takes a single directory
        my @dirs;

        if defined $dir and $dir.IO.d {
            @dirs = [$dir.IO];
        } elsif defined $dir {
            fail "$dir does not exist, or is not a directory";
        } else {
            @dirs = get-doc-locations();
        }

        if not $query.contains('.') {
            my Perl6::Documentable @results = type-search($query, :dir(@dirs.first));
            show-t-search-results(@results);
        } else {
            my @squery = $query.split('.');

            if not @squery.elems == 2 {
                fail 'Malformed input, example: Map.elems';
            } else {
                my Perl6::Documentable @results = type-search(@squery[0], :routine(@squery[1]), :dir(@dirs.first));
                show-t-search-results(@results);
            }
        }
    }

    multi MAIN(Str :r($routine), Str :d($dir)) {
        my @dirs;


        if defined $dir and $dir.IO.d {
            @dirs = [$dir];
        } elsif defined $dir {
            fail "$dir does not exist, or is not a directory";
        } else {
            @dirs = get-doc-locations();
        }

        my Perl6::Documentable @results = routine-search($routine, :topdirs(@dirs));
        show-r-search-results(@results);
    }
}
