use Documentable;
use Documentable::Primary;
use Pod::Cache;
use Pod::To::Text;

my class X::Rakudoc is Exception {
    has $.message;
}

my class X::Rakudoc::BadQuery is X::Rakudoc {}

class Rakudoc:auth<github:Raku>:api<1>:ver<0.1.9> {
    has @.doc-sources;
    has $.data-dir;
    has $!cache;

    submethod TWEAK(
        :$doc-sources is copy,
        :$no-default-docs,
        :$data-dir,
    ) {
        $doc-sources = grep *.defined, $doc-sources<>;
        if !$doc-sources and %*ENV<RAKUDOC> {
            $doc-sources = %*ENV<RAKUDOC>.split(',').map(*.trim);
        }
        $doc-sources = [$doc-sources<>] unless $doc-sources ~~ Positional;
        unless $no-default-docs {
            $doc-sources.append:
                $*REPO.repo-chain.map({.?abspath.IO // Empty})».add('doc');
        }
        @!doc-sources = map *.resolve, grep *.d, map *.IO, @$doc-sources;

        $!data-dir = self!resolve-data-dir($data-dir // %*ENV<RAKUDOC_DATA>);
    }

    role Request {
        has $.rakudoc;
        has $.section;
    }

    role Doc {
        has $.rakudoc;
        has $.name;
        has $.origin;

        method pod { ... }
        method gist { ... }
    }

    class Doc::Documentable does Doc {
        has $.def;
        has $!documentable;

        method pod {
            my @pod;
            @pod = $.documentable.defs.grep({.name eq $!def}).map(*.pod)
                if $!def;
            @pod || $.documentable.pod;
        }
        method gist {
            "Doc(*{$!origin.absolute})"
        }
        method filename {
            ~ $!origin.basename.IO.extension('', :parts(1))
        }
        method documentable {
            return $_ with $!documentable;
            my $pod = $!rakudoc.cache.pod($!origin.absolute);

            die join "\n",
                    "Unexpected: doc pod '$.origin' has multiple elements:",
                    |$pod.pairs.map(*.raku)
                if $pod.elems > 1;

            # Documentable is strict about Pod contents currently, and will
            # probably throw (X::Adhoc) for anything that isn't in the main
            # doc repo.
            # TODO Add more specific error handling & warning text
            #CATCH { default { } }

            $!documentable = Documentable::Primary.new:
                :pod($pod.first),
                :$.filename,
                :source-path($!origin.absolute);
        }
    }

    class Doc::CompUnit does Doc {
        has $.def;

        method !source {
            my $prefix = $!origin.repo.prefix;
            my $source = $!origin.distribution.meta<source>;
            if $prefix && $source && "$prefix/sources/$source".IO.e {
                "$prefix/sources/$source".IO.slurp
            }
            else {
                ''
            }
        }
        method pod {
            $!rakudoc.cache.pod($!origin.handle) || self!source
            # TODO Handle $.def
            # TODO Find docs in resources/doc
        }
        method gist {
            "Doc({$!origin.repo.prefix} {$!origin})"
        }
        method filename {
            ~ $!origin
        }
    }

    class Request::Name does Request {
        has $.name;
        has $.def;
        method Str { "'{$.name}{'.' ~ $.def if $.def}'" }
    }

    class Request::Def does Request {
        has $.def;
        method Str { "'.{$.def}'" }
    }

    grammar Request::Grammar {
        token TOP { <module> <definition>? | <definition> }
        token module { <-[\s.]> + }
        token definition { '.' <( <-[\s.]> + )> }
    }

    method request(Str $query) {
        Request::Grammar.new.parse($query)
            or die X::Rakudoc::BadQuery.new: :message("unrecognized query: $query");

        if $/<module> {
            Request::Name.new: :name($/<module>), :def($/<definition>)
        }
        else {
            Request::Def.new: :def($/<definition>)
        }
    }

    method search(Request $req) {
        given $req {
            when Request::Name {
                # Names can match either a doc file or an installed module
                flat
                    self.search-doc-sources($req.name).map({
                        Doc::Documentable.new: :rakudoc(self),
                            :origin($_), :def($req.def)
                    }),
                    self!locate-curli-module(~$req.name).map({
                        Doc::CompUnit.new: :rakudoc(self),
                            :origin($_), :def($req.def);
                    })
            }

            when Request::Def {
                note "NYI search by method/routine definition";
                Empty
            }
        }
    }

    method search-doc-sources($str) {
        my $fragment = reduce { $^a.add($^b) }, '.'.IO, | $str.split('::');

        grep *.e,
        map -> $dir, $ext { $dir.add($fragment).extension(:0parts, $ext) },
        flat @!doc-sources.map({
                | .dir(:test(*.starts-with('.').not)).grep(*.d)
            }) X <pod6 rakudoc>
    }

    method render(Doc $doc) {
        join "\n\n", map { pod2text($_).trim ~ "\n" }, $doc.pod
    }

    method cache {
        return $!cache if $!cache;
        $!data-dir.mkdir unless $!data-dir.d;
        $!cache = Pod::Cache.new: :cache-path($!data-dir.add('cache'));
    }

    method !resolve-data-dir($data-dir) {
        # A major limitation is that currently there can only be a single
        # Pod::Cache instance in a program (due to precompilation guts?)
        # See https://github.com/finanalyst/raku-pod-from-cache/blob/master/t/50-multiple-instance.t
        #
        # This precludes having a read-only system-wide cache and a
        # user-writable fallback. So for now, each user must build & update
        # their own cache.

        return $data-dir.IO.resolve(:completely) if $data-dir;

        # By default, this will be ~/.cache/raku/rakudoc-data on most Unix
        # distributions, and ~\.raku\rakudoc-data on Windows and others
        my IO::Path @candidates = map *.add('rakudoc-data'),
            # Here is one way to get a system-wide cache: if all raku users are
            # able to write to the raku installation, then this would probably
            # work; of course, this will also require file locking to prevent
            # users racing against each other while updating the cache / indexes
            #$*REPO.repo-chain.map({.?prefix.?IO // Empty})
            #        .grep({ $_ ~~ :d & :w })
            #        .first(not *.absolute.starts-with($*HOME.absolute)),
            %*ENV<XDG_CACHE_HOME>.?IO.?add('raku') // Empty,
            %*ENV<XDG_CACHE_HOME>.?IO // Empty,
            $*HOME.add('.raku'),
            $*HOME.add('.perl6'),
            $*CWD;
            ;

        @candidates.first(*.f) // @candidates.first;
    }

    method !locate-curli-module($short-name) {
        # TODO This is only the first one; keep on searching somehow?
        my $cu = try $*REPO.need(CompUnit::DependencySpecification.new: :$short-name);
        $cu // Empty
    }
}
