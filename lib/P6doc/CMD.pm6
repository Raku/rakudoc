use P6doc;
use P6doc::Utils;
use P6doc::Index;

use Perl6::Documentable;

use JSON::Fast;

package P6doc::CMD {
    my $PROGRAM-NAME = "p6doc";

    #`[
    sub USAGE() {
        say q:to/END/;
            p6doc is a tool for reading perl6 documentation.

            Usage:

                p6doc <command> [argument]

            Commands:

                build       build an index for p6doc -f
                list        list the index keys
                env         show information on p6doc's environment

            Examples:

                p6doc Map
                p6doc Map.new
            END
    }

    multi sub MAIN($docee, Bool :$n) {
        # On windows, if input is not surrounded by '', it will be malformed
        # Example: `p6doc X::IO` will pass `X:/:IO` to MAIN.
        # This should be checked for and corrected.

        return MAIN($docee, :f, :$n) if defined $docee.index('.');

        say get-docs(locate-module($docee).IO, :package($docee));
    }

    multi sub MAIN($docee, Bool :$f!, Bool :$n) {
        my ($package, $method) = $docee.split('.');
        if ! $method {

            if not INDEX.IO.e {
                say "building index on first run. Please wait...";
                build-index(INDEX);
            }

            my %data = from-json slurp(INDEX);

            my $final-docee = disambiguate-f-search($docee, %data);

            # NOTE: This is a temporary fix, since disambiguate-f-search
            #       does not properly handle independent routines right now.
            if $final-docee eq '' {
                $final-docee = ('independent-routines', $docee).join('.');
            }

            ($package, $method) = $final-docee.split('.');

            my $m = locate-module($package);

            say get-docs($m.IO, :section($method), :$package);
        } else {
            my $m = locate-module($package);

            say get-docs($m.IO, :section($method), :$package);
        }
    }

    multi sub MAIN(Bool :$l!) {
        my @paths = search-paths() X~ <Type/ Language/>;
        my @modules;
        for @paths -> $dir {
            for dir($dir).sort -> $file {
                @modules.push: $file.basename.subst( '.'~$file.extension,'') if $file.IO.f;
            }
        }
        @modules.append: list-installed().map(*.name);
        .say for @modules.unique.sort;
    }

    multi sub MAIN(Str $file where $file.IO.e, Bool :$n) {
        say get-docs($file.IO);
    }

    # index related
    multi sub MAIN('env') {
        my Str $index-info = "Index file: {INDEX}";
        my Str $doc-info = "Doc folder: {get-doc-locations}";

        say $index-info;
        say $doc-info;
    }

    multi sub MAIN('build') {
        say "Building index file...";
        build-index(INDEX);
    }
    ]

    ###
    ###
    ###

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
