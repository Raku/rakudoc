use Documentable;
use Documentable::Primary;
use Pod::To::Text;

my class X::Rakudoc is Exception {
    has $.message;
}

class Rakudoc:auth<github:Raku>:api<1>:ver<0.1.9> {
    role Request {
        has $.rakudoc;
        has $.section;
    }

    class Request::Name does Request {
        has $.name;
        method Str { "'$.name'" }
    }

    method request(Str $query) {
        Request::Name.new: :rakudoc(self), :name($query);
    }

    method search(Request $request) {
        Empty
    }
}
