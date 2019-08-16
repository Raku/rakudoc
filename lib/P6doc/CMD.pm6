use P6doc;
use P6doc::Utils;
use P6doc::Index;

use Perl6::Documentable;

use JSON::Fast;

package P6doc::CMD {
    my $PROGRAM-NAME = "p6doc";

    sub USAGE() {
        say q:to/END/;
            p6doc, a tool for reading perl6 documentation.

            Usage:
                p6doc <file>
                p6doc [<option>...] <type>
                p6doc [<option>...] <type>.<routine>
                p6doc [<option>...] -r <routine>

            Where:
                <file>                  A Perl 6 POD file
                <Type>                  A Perl 6 type or class
                <routine>               A routine or method associated with a type

            Options:
                [-d | --directory]      manually specify a doc directory
                [-h | --help]           print usage information
                [-b | --build]          build a routine index
                [-r | --routine]        search by routine name

            Examples:
                p6doc ~/my-pod-file.pod6
                p6doc IO::Spec
                p6doc Map.new

            END
    }

    our proto MAIN(|) is export {
        {*}
    }

    multi MAIN(Bool :h(:$help)?) {
        USAGE();

        exit;
    }

    multi MAIN(Str $pod-file where *.IO.e) {
        say load-pod-to-txt($pod-file.IO);
    }

    multi MAIN(Str $query, Str :d($dir)) {
        my @doc-dirs;

        if defined $dir and $dir.IO.d {
            # If directory is provided via `-d`, only look there
            # TODO: There should be a way to detect whether the provided
            # directory is the regular standard documentation, or an arbitrary
            # folder containing .pod6 files.
            # Also the categories should be pulled from Perl6::Documentable, rather
            # than hardcoded here.
            @doc-dirs = [$dir.IO.add('Type')];
        } elsif defined $dir {
            fail "$dir does not exist, or is not a directory";
        } else {
            # If no directory is provided, search in a given set of standard
            # paths
            @doc-dirs = get-doc-locations() X~ 'Type';
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
        my $routine-index-path = routine-index-path();

        if $routine-index-path.e && not INDEX.z {
            my @search-results = routine-search($routine, $routine-index-path).list;

            if @search-results.elems == 1 {

                if defined $dir && $dir.IO.d {
                    MAIN("{@search-results.first}.{$routine}", :d($dir));
                } else {
                    MAIN("{@search-results.first}.{$routine}");
                }
            } else {
                say "";
                say "$routine in:";
                say "";
                for @search-results -> $type-name {
                    say $type-name;
                }
            }
        } else {
            say "No index file found, build index first.";
        }
    }

    multi MAIN(Bool :b($build), Str :d($dir)) {
        my $routine-index-path = routine-index-path();

        if defined $dir and $dir.IO.d {
            say "Building index...";
            write-routine-index-file($routine-index-path, [$dir.IO]);
            say "Index written to {$routine-index-path}";
        } elsif defined $dir {
            fail "$dir does not exist, or is not a directory";
        } else {
            say "Building index...";
            # TODO: write-routine-index and create-routine-index should
            # take an array of directories instead of a single one
            write-routine-index-file($routine-index-path, get-doc-locations());
            say "Index written to {$routine-index-path}";
        }
    }
}
