use Rakudoc;
use Rakudoc::Utils;
use Rakudoc::Index;

use Documentable;

use JSON::Fast;

package Rakudoc::CMD {
    my $PROGRAM-NAME = "rakudoc";

    sub USAGE() {
        say q:to/END/;
            rakudoc, a tool for reading Raku documentation

            Usage:
                rakudoc <file>
                rakudoc [<option>...] <type>
                rakudoc [<option>...] <type>.<routine>
                rakudoc [<option>...] -r=<routine>

            Where:
                <file>                  A Raku POD file
                <type>                  A Raku type or class
                <routine>               A routine or method associated with a type

            Options:
                [-b | --build]          build a routine index
                [-d | --dir]            manually specify a doc directory
                [-h | --help]           print usage information
                [-n | --nopager]        deactivate pager usage for output

            Examples:
                rakudoc ~/my-pod-file.rakumod
                rakudoc IO::Spec
                rakudoc Map.new

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

    multi MAIN(Str $query, Str :d(:$dir), Bool :n(:$nopager)) {
        my $use-pager = True;
        $use-pager = False if $nopager;

        my @doc-dirs;

        if defined $dir and $dir.IO.d {
            # If directory is provided via `-d`, only look there
            # TODO: There should be a way to detect whether the provided
            # directory is the regular standard documentation, or an arbitrary
            # folder containing .rakudoc files.
            # Also the categories should be pulled from Documentable, rather
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
            my Documentable @documentables;
            my Documentable @search-results;

            for @doc-dirs -> $dir {
                @pod-paths.append: find-type-files($query, $dir);
            }

            @documentables = process-type-pod-files(@pod-paths);
            @search-results = type-search($query, @documentables);

            show-t-search-results(@search-results, :use-pager($use-pager));

        } else {
            # e.g. split `Map.new` into `Map` and `new`
            my @squery = $query.split('.');

            if not @squery.elems == 2 {
                fail 'Malformed input, example: Map.elems';
            } else {
                my IO::Path @pod-paths;
                my Documentable @documentables;
                my Documentable @search-results;

                for @doc-dirs -> $dir {
                    @pod-paths.append: find-type-files(@squery[0], $dir);
                }

                @documentables = process-type-pod-files(@pod-paths);
                @search-results = type-search(@squery[0],
                                              :routine(@squery[1]),
                                              @documentables);

                show-t-search-results(@search-results, :use-pager($use-pager));
            }
        }
    }

    multi MAIN(Str :r(:$routine), Str :d(:$dir), Bool :n(:$nopager)) {
        my $use-pager = True;
        $use-pager = False if $nopager;

        my $routine-index-path = routine-index-path();

        if $routine-index-path.e && not INDEX.z {
            my @search-results = routine-search($routine, $routine-index-path).list;

            if @search-results.elems == 1 {

                if defined $dir && $dir.IO.d {
                    MAIN("{@search-results.first}.{$routine}", :d($dir), :n($nopager));
                } else {
                    MAIN("{@search-results.first}.{$routine}", :n($nopager));
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

    multi MAIN(Bool :b(:$build), Str :d(:$dir)) {
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
