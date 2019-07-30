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
        my @doc-dirs;

        if defined $dir and $dir.IO.d {
            # If directory is provided via `-d`, only look there
            @doc-dirs = [$dir.IO];
        } elsif defined $dir {
            fail "$dir does not exist, or is not a directory";
        } else {
            # If no directory is provided, search in a given set of standard
            # paths
            @doc-dirs = get-doc-locations();
        }

        if not $query.contains('.') {
            my IO::Path @pod-paths;
            my Perl6::Documentable @documentables;
            my Perl6::Documentable @search-results;

            for @doc-dirs -> $dir {
                @pod-paths.append: find-type-files($query, $dir);
            }

            @documentables = process-type-pod-files(@pod-paths);
            @search-results = type-search($query, @documentables);

            show-t-search-results(@search-results);

        } else {
            # e.g. split `Map.new` into `Map` and `new`
            my @squery = $query.split('.');

            if not @squery.elems == 2 {
                fail 'Malformed input, example: Map.elems';
            } else {
                my IO::Path @pod-paths;
                my Perl6::Documentable @documentables;
                my Perl6::Documentable @search-results;

                for @doc-dirs -> $dir {
                    @pod-paths.append: find-type-files(@squery[0], $dir);
                }

                @documentables = process-type-pod-files(@pod-paths);
                @search-results = type-search(@squery[0],
                                              :routine(@squery[1]),
                                              @documentables);

                show-t-search-results(@search-results);

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
