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

multi MAIN(
    #| Examples: 'Map'
    $query,
) {
    my $rakudoc = Rakudoc.new;
    my $request = $rakudoc.request: $query;
    my @docs = $rakudoc.search: $request;

    my $text = @docs.join("\n\n")
        or die X::Rakudoc.new: :message("No results for $request");

    put $text;
}

multi MAIN(Bool :h(:$help)!, |_) {
    put $*USAGE;
}
