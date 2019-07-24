use P6doc::Utils;

use Pod::Load;
use Perl6::Documentable;
use Perl6::Documentable::Processing;

use JSON::Fast;
use Pod::To::Text;

use Path::Finder;


unit module P6doc;

constant DEBUG      = %*ENV<P6DOC_DEBUG>;
constant INTERACT   = %*ENV<P6DOC_INTERACT>;

# die with printing a backtrace
my class X::P6doc is Exception {
    has $.message;
    multi method gist(X::P6doc:D:) {
        self.message;
    }
}

sub module-names(Str $modulename) returns Seq is export {
    return $modulename.split('::').join('/') X~ <.pm .pm6 .pod .pod6>;
}

sub locate-module(Str $modulename) is export {
    my @candidates = search-paths() X~ </ Type/ Language/> X~ module-names($modulename).list;
    DEBUG and warn :@candidates.perl;
    my $m = @candidates.first: *.IO.f;

    unless $m.defined {
        # not "core" pod now try for panda or zef installed module
        $m = locate-curli-module($modulename);
    }

    unless $m.defined {
        my $message = join "\n",
        "Cannot locate $modulename in any of the following paths:",
        search-paths.map({"  $_"});
        X::P6doc.new(:$message).throw;
    }

    return $m;
}

sub is-pod(IO::Path $p) returns Bool {
    if not open($p).lines.grep( /^'=' | '#|' | '#='/ ) {
        return False
    } else {
        return True
    }
}

sub get-docs(IO::Path $path, :$section, :$package is copy) returns Str is export {
    if not $path.IO.e {
        fail "File not found: $path";
    }

    if (is-pod($path)) eq False {
        fail "No Pod found in $path";
    }

    my $proc = Proc.new: :err, :out, :merge;

    if $section.defined {
        %*ENV<PERL6_POD_HEADING> = $section;
        my $i = findbin().add('../lib');

        $proc.spawn($*EXECUTABLE, "-I$i", "--doc=SectionFilter", $path);
        return $proc.out.slurp: :close;
    } else {
        $proc.spawn($*EXECUTABLE, "--doc", $path);
        return $proc.out.slurp: :close;
    }
}

sub show-docs(Str $docstr, :$no-pager) is export {
    # show-docs will only handle paging and formatting, if desired
    X::NYI.new( feature => "sub {&?ROUTINE.name}",
                did-you-mean => "get-docs",
                workaround => "Please be patient." ).throw;
}

sub disambiguate-f-search($docee, %data) is export {
    my %found;

    for <routine method sub> -> $pref {
        my $ndocee = $pref ~ " " ~ $docee;

        if %data{$ndocee} {
            my @types = %data{$ndocee}.values>>.Str.grep({ $^v ~~ /^ 'Type' / });
            @types = [gather @types.deepmap(*.take)].unique.list;
            @types.=grep({!/$pref/});
            %found{$ndocee}.push: @types X~ $docee;
        }
    }

    my $final-docee;
    my $total-found = %found.values.map( *.elems ).sum;
    if ! $total-found {
        fail "No documentation found for a routine named '$docee'";
    } elsif $total-found == 1 {
        $final-docee = %found.values[0];
    } else {
        say "We have multiple matches for '$docee'\n";

        my %options;
        for %found.keys -> $key {
            %options{$key}.push: %found{$key};
        }
        my @opts = %options.values.map({ @($^a) });

        # 's' => Type::Supply.grep, ... | and we specifically want the %found values,
        #                               | not the presentation-versions in %options
        if INTERACT {
            my $total-elems = %found.values.map( +* ).sum;
            if +%found.keys < $total-elems {
                my @prefixes = (1..$total-elems) X~ ") ";
                say "\t" ~ ( @prefixes Z~ @opts ).join("\n\t") ~ "\n";
            } else {
                say "\t" ~ @opts.join("\n\t") ~ "\n";
            }
            $final-docee = prompt-with-options(%options, %found);
        } else {
            say "\t" ~ @opts.join("\n\t") ~ "\n";
            exit 1;
        }
    }

    return $final-docee;
}

sub prompt-with-options(%options, %found) {
    my $final-docee;

    my %prefixes = do for %options.kv -> $k,@o { @o.map(*.comb[0].lc) X=> %found{$k} };

    if %prefixes.values.grep( -> @o { +@o > 1 } ) {
        my (%indexes,$base-idx);
        $base-idx = 0;
        for %options.kv -> $k,@o {
            %indexes.push: @o>>.map({ ++$base-idx }) Z=> @(%found{$k});
        }
        %prefixes = %indexes;
    }

    my $prompt-text = "Narrow your choice? ({ %prefixes.keys.sort.join(', ') }, or !{ '/' ~ 'q' if !%prefixes<q> } to quit): ";

    while prompt($prompt-text).words -> $word {
        if $word  ~~ '!' or ($word ~~ 'q' and !%prefixes<q>) {
            exit 1;
        } elsif $word ~~ /:i $<choice> = [ @(%prefixes.keys) ] / {
            $final-docee = %prefixes{ $<choice>.lc };
            last;
        } else {
            say "$word doesn't seem to apply here.\n";
            next;
        }
    }

    return $final-docee;
}

sub locate-curli-module($module) {
    my $cu = try $*REPO.need(CompUnit::DependencySpecification.new(:short-name($module)));
    unless $cu.DEFINITE {
        fail "No such type '$module'";
        #exit 1;
    }
    return ~ $cu.repo.prefix.child('sources/' ~ $cu.repo-id);
}

# see: Zef::Client.list-installed()
# Eventually replace with CURI.installed()
# https://github.com/rakudo/rakudo/blob/8d0fa6616bab6436eab870b512056afdf5880e08/src/core/CompUnit/Repository/Installable.pm#L21
sub list-installed() is export {
    my @curs       = $*REPO.repo-chain.grep(*.?prefix.?e);
    my @repo-dirs  = @curs>>.prefix;
    my @dist-dirs  = |@repo-dirs.map(*.child('dist')).grep(*.e);
    my @dist-files = |@dist-dirs.map(*.IO.dir.grep(*.IO.f).Slip);

    my $dists := gather for @dist-files -> $file {
        if try { Distribution.new( |%(from-json($file.IO.slurp)) ) } -> $dist {
            my $cur = @curs.first: {.prefix eq $file.parent.parent}
            my $dist-with-prefix = $dist but role :: { has $.repo-prefix = $cur.prefix };
            take $dist-with-prefix;
        }
    }
}

###
### NEXT
###

#| Create a Perl6::Documentable::Registry for the given directory
sub compose-registry(
    $topdir,
    @dirs = ['Type'],
	--> Perl6::Documentable
) {
    my $registry = process-pod-collection(
        cache => False,
        verbose => False,
        topdir => $topdir,
        dirs => @dirs
    );
    $registry.compose;

    return $registry
}

#| Receive a list of paths to pod files and process them, return a list of
#| Perl6::Documentable objects
sub process-type-pods(
	IO::Path @files,
	--> Array[Perl6::Documentable]
) is export {
	my Perl6::Documentable @results;

    for @files.list -> $f {
        my $documentable = process-pod-source(
            kind => "type",
            pod => load($f)[0],
            filename => $f.Str,
        );
        @results.push($documentable);
    }

    return @results;
}

#| Search for relevant files in a given directory (recursively, if necessary),
#| and return a list of the results.
#| $type-name is the name of the type in the form `Str`, `IO::Spec::Unix` etc..
#| This assumes that $dir is the base directory for the pod files, example: for
#| the standard documentation folder 'doc', `$dir` should be `'doc'.IO.add('Type')`.
sub type-list-files(
	Str $type-name,
	$dir,
	--> Array[IO::Path]
) is export {
    my IO::Path @results;
    my $search-name;

    # TODO: Depth not yet optimal
    my $query-depth = 0..2;

    my $finder = Path::Finder;

    if $type-name.contains('::') {
        $query-depth = $type-name.split('::').elems + 1;
        $search-name = $type-name.split('::').tail;

    } else {
        $search-name = $type-name;
    }

    $finder = $finder.depth($query-depth);
    $finder = $finder.name("{$search-name}.pod6");

    for $finder.in($dir, :file) -> $file {
        @results.push($file);
    }

    return @results;
}

#| Search for a single Routine/Method/Subroutine, e.g. `split`
# TODO: type-search already profits from pre sieving, routine search does
# not have any optimization yet!
sub routine-search(
    Str $routine,
    :@topdirs = get-doc-locations(),
	--> Array[Perl6::Documentable]
) is export {
    my Perl6::Documentable @results;

    for @topdirs -> $td {
        my $registry = compose-registry($td);

        # The result from `.lookup` is containerized, thus we use `.list`
        for $registry.lookup($routine, :by<name>).list -> $r {
            @results.append: $r;
        }
    }

    return @results
}

#| Lookup documentation in association with a type, e.g. `Map`, `Map.new`.
#| `$dir` makes the same assumption as `type-list-files`.
# TODO: might be cleaner to just give it a list of Perl6::Documentable objects
sub type-search(
	Str $type-name,
	Str :$routine?,
	IO::Path :$dir where *.d = get-doc-locations().first,
	--> Array[Perl6::Documentable]
)  is export {
	my Perl6::Documentable @results;

    my IO::Path @files = type-list-files($type-name, $dir);
    @results = process-type-pods(@files);

    # Old, filter for class
    #@results = @results.grep: *.subkinds.contains('class');
    # New, filter only by name, since we already pre sieve with type-list-files
    @results = @results.grep: *.name eq $type-name;

    # If we provided a routine to search for, we now look for it inside the found classes
    # and return an array of those results instead
    if defined $routine {
        my Perl6::Documentable @routine-results;

        for @results -> $rs {
            # Loop definitions, look for searched routine
            # `.defs` contains a list of Perl6::Documentables defined inside
            # a given object.
            for $rs.defs -> $def {
                if $def.name eq $routine {
                    @routine-results.push($def);
                }
            }
        }

        return @routine-results;
    }

    return @results
}

#|
sub show-r-search-results(Perl6::Documentable @results) is export {
    if @results.elems == 1 {
        say pod2text(@results.first.pod);
    } elsif @results.elems < 1 {
        say "No matches";
    } else {
        say 'Multiple matches:';
        for @results -> $r {
            # `.origin.name` gives us the correct name of the pod our
            # documentation is defined in originally
            say "    {$r.origin.name} {$r.subkinds} {$r.name}";
        }
    }
}

#| Print the search results. This renders the documentation if `@results == 1`
#| Or lists names and associated types if `@results > 1`.
sub show-t-search-results(Perl6::Documentable @results) is export {
    if @results.elems == 1 {
        say pod2text(@results.first.pod);
    } elsif @results.elems < 1 {
        say "No matches";
    } else {
        say 'Multiple matches:';
        for @results -> $r {
            say "    {$r.subkinds} {$r.name}";
        }
    }
}

# vim: expandtab shiftwidth=4 ft=perl6
