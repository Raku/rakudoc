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

sub display(*@docs) {
    my $text = @docs.join("\n\n{'=' x 78}\n");;
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

multi MAIN(
    #| Examples: 'Map'
    $query,
) {
    my $rakudoc = Rakudoc.new;
    my $request = $rakudoc.request: $query;
    my @docs = $rakudoc.search: $request
        or die X::Rakudoc.new: :message("No results for $request");

    display @docs.map: { $rakudoc.render($_) };
}

multi sub MAIN(
    Bool :V(:$version)!,
) {
    put "$*PROGRAM :auth<{Rakudoc.^auth}>:api<{Rakudoc.^api}>:ver<{Rakudoc.^ver}>";
}

multi MAIN(Bool :h(:$help)!, |_) {
    put $*USAGE;
}
