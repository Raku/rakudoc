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

    my $fh;
    my $pager = $*OUT.t && [//] |%*ENV<RAKUDOC_PAGER PAGER>, 'more';
    if $pager {
        # TODO Use Shell::WordSplit or whatever is out there; for now this
        # makes a simple 'less -Fr' work
        $pager = run :in, |$pager.comb(/\S+/);
        $fh = $pager.in;
    }
    else {
        $fh = $*OUT;
    }

    for @docs {
        $fh.print: "\n" if $++;
        $fh.print: "# {.gist}\n\n";

        my $text = $rakudoc.render($_);

        $fh.put: $text;
    }

    if $pager {
        $fh.close;

        # Ensure pager is done
        #$pager.exitcode;
    }

    if $rakudoc.warnings {
        $*ERR.print: "* WARNING\n" ~ $rakudoc.warnings.map({"* $_\n"}).join;
        $rakudoc.warnings = Empty;
    }
}

subset Directories of Str;
# Positional handling is buggy, rejects specifying just one time
#subset Directory of Positional where { all($_) ~~ Str };

multi MAIN(
    #| Example: 'Map', 'IO::Path.add', '.add'
    $query,
    #| Additional directories to search for documentation
    Directories :d(:$doc-sources),
    #| Use only directories in --doc-sources / $RAKUDOC
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
    Directories :d(:$doc-sources),
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

sub help-text {
    $*USAGE.subst(:g, $*PROGRAM, $*PROGRAM.basename)
}
multi MAIN(Bool :h(:$help)!) {
    put help-text();
}

multi MAIN(|) is hidden-from-USAGE {
    note help-text();
    exit 2;
}
