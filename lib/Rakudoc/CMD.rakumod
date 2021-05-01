unit module Rakudoc::CMD;

use Rakudoc;

our proto MAIN(|) is export {

    {*}

    CATCH {
        when X::Rakudoc {
            $*ERR.put: $_;

            if %*ENV<RAKUDOC_TEST> {
                # Meaningless except to t/01-cmd.t
                return False;
            }

            exit 2;
        }
    }

    # Meaningless except to t/01-cmd.t
    True;
}

sub display($rakudoc, *@docs) {
    my $text = '';

    if $rakudoc.warnings {
        $text ~= "* WARNING\n" ~ $rakudoc.warnings.map({"* $_\n"}).join ~ "\n";
        $rakudoc.warnings = Empty;
    }

    $text ~= join "\n\n", @docs.map: {
        "# {.gist}\n\n" ~ $rakudoc.render($_)
    }

    my $pager = $*OUT.t && [//] |%*ENV<RAKUDOC_PAGER PAGER>, 'more';
    if $pager {
        # TODO Use Shell::WordSplit or whatever is out there; for now this
        # makes a simple 'less -Fr' work
        $pager = run :in, |$pager.comb(/\S+/);
        $pager.in.spurt($text, :close);
    }
    else {
        put $text;
    }
}

subset Directories of Str;
# Positional handling is buggy, rejects specifying just one time
#subset Directory of Positional where { all($_) ~~ Str };

multi MAIN(
    #| Example: 'Map', 'IO::Path', 'IO::Path.'
    $query,
    #| Additional directories to search for documentation
    Directories :d(:$doc-sources),
    #| Use only directories specified with --doc / $RAKUDOC
    Bool :D(:$no-default-docs),
) {
    my $rakudoc = Rakudoc.new:
        :$doc-sources,
        :$no-default-docs,
        ;
    my $request = $rakudoc.request: $query;
    my @docs = $rakudoc.search: $request
        or die X::Rakudoc.new: :message("No results for $request");

    display $rakudoc, @docs;
}

multi sub MAIN(
    #| Index all documents found in doc source directories
    Bool :b(:$build-index)!,
    #| Additional directories to search for documentation
    Directories :d(:$doc-sources),
    #| Use only directories specified with --doc / $RAKUDOC
    Bool :D(:$no-default-docs),
) {
    my $rakudoc = Rakudoc.new:
        :$doc-sources,
        :$no-default-docs,
        ;
    $rakudoc.index.build;
}

multi sub MAIN(
    Bool :V(:$version)!,
) {
    put "$*PROGRAM :auth<{Rakudoc.^auth}>:api<{Rakudoc.^api}>:ver<{Rakudoc.^ver}>";
}

#| Show this help message
multi MAIN(Bool :h(:$help)!, |ARGUMENTS) {
    put $*USAGE;
}
