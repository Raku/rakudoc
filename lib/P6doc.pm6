use P6doc::Utils;

use Pod::Load;

use Perl6::TypeGraph;
use Perl6::Documentable;
use Perl6::Documentable::File;
use Perl6::Documentable::Registry;

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

# NOTE: It appears that `Perl6::Documentable` can be used instead of
# the more specific `Perl6::Documentable::File`. Noting this here in case
# this circumstance changes in the future.
# The following uses `Perl6::Documentable` to annotate any Documentable
# objects.

#| Receive a list of paths to pod files and process them, return an array of
#| processed Perl6::Documentable objects
sub process-type-pod-files(
    IO::Path @files,
    --> Array[Perl6::Documentable]
) is export {
    my Perl6::Documentable @results;

    for @files.list -> $f {
        my $documentable = Perl6::Documentable::File.new(
            # Be aware that Pod::Load's `load` returns an array,
            # because of that we take the first element
            pod => load($f).first,
            filename => $f.basename.IO.extension('').Str,
        );

        @results.push($documentable);
    }

    @results
}

#| Translate a Type name in form `Map`, `IO::Spec::Unix` into a file path.
#| The resulting path is relative to the doc folder.
sub type-path-from-name(
    Str $type-name,
    --> IO::Path
) is export {
    if not $type-name.contains('::') {
        return ($type-name.IO ~ '.pod6').IO
    } else {
        # Replace `::` with the directory separator specific to the
        # platform
        return ($type-name.subst('::', $*SPEC.dir-sep) ~ '.pod6').IO;
    }
}

#| Search for relevant files in a given directory (recursively, if necessary),
#| and return a list of the results.
#| $type-name is the name of the type in the form `Map`, `IO::Spec::Unix` etc..
#| This assumes that $dir is the base directory for the pod files, example: for
#| the standard documentation folder 'doc', `$dir` should be `'doc'.IO.add('Type')`.
sub find-type-files(
    Str $type-name,
    $dir,
    --> Array[IO::Path]
) is export {
    my IO::Path @results;
    my $search-name;

    my $finder = Path::Finder;

    if $type-name.contains('::') {
        # The :: already tell us the folder depth, no reason to look anywhere
        # else.
        $finder = $finder.depth($type-name.split('::').elems);
        $search-name = $type-name.split('::').tail;
    } else {
        $finder = $finder.depth(1);
        $search-name = $type-name;
    }

    # NOTE: There is currently an inconsistency when it comes to independent routines.
    # In Perl6::Documentable, the `name` attribute for the Documentable object containing
    # a given routine will only be `routines`, while the actual filename for the `.pod6` file for
    # independent routines in the Perl 6 documentation is `independent-routines.pod6`.
    #
    # For now, this is treated as an edge case here.
    if $search-name eq 'routines' {
        $finder = $finder.name("independent-routines.pod6");
    } else {
        $finder = $finder.name("{$search-name}.pod6");
    }

    for $finder.in($dir, :file) -> $file {
        @results.push($file);
    }

    @results
}

#| Lookup documentation in association with a type, e.g. `Map`, `Map.new`.
sub type-search(
    Str $type-name,
    Perl6::Documentable @documentables,
    Str :$routine?,
    --> Array[Perl6::Documentable]
) is export {
    my Perl6::Documentable @results;

    # First, remove elements where name does not match
    @results = @documentables.grep: *.name eq $type-name;

    # If a routine to search for has been provided, we now look for it inside
    # the found types, and return those results instead
    if defined $routine {
        my Perl6::Documentable @routine-results;

        for @results -> $rs {
            # Loop definitions, look for searched routine
            # `.defs` contains a list of Perl6::Documentable defined inside a
            # given object
            for $rs.defs -> $def {
                if $def.name eq $routine {
                    @routine-results.push($def);
                }
            }
        }
        return @routine-results;
    }

    # If no $routine was provided, only looking for the Type name was enough
    @results
}

#| Search for all `.pod6` files in a given directory (and subdirectories)
sub find-pod-files(
    $dir,
    --> Array[IO::Path]
) is export {
    my IO::Path @results;

    my $finder = Path::Finder;

    $finder = $finder.ext('pod6');

    for $finder.in($dir, :file) -> $file {
        @results.push($file);
    }

    @results
}

#| Create a routine index for Perl 6 standard documentation.
#| $topdir should be a default topdirectory with the subdirectory
#| 'Type' inside.
#| The resulting index has the routine names as keys, each key harbors
#| an array containing the Types the routine is associated with
sub create-routine-index(
    IO::Path $topdir,
    --> Hash
) is export {
    my %routine-index;

    my $registry = Perl6::Documentable::Registry.new(
        # `Perl6::Documentable::Registry`'s $topdir attribute takes a string instead
        # of an `IO::Path` currently.
        topdir => $topdir.Str,
        dirs => ['Type'],
        verbose => False,
        use-cache => False,
    );
    $registry.compose;

    # Looping the result of `lookup`, the key only contains numbering.
    # We only need the values
    # NOTE: If `gist` is not used on `Kind`, lookup results in an error, this
    # is possibly a bug. The tests[1] for `Perl6::Documentable` use `gist`
    # as well, but the documentation[2] does not mention it.
    #
    # [1]:https://github.com/antoniogamiz/Perl6-Documentable/blob/50577c0eb1e684b76053c56d9523f9aec9cfc652/t/301-registry.t#L25
    # [2]:https://github.com/antoniogamiz/Perl6-Documentable/blob/50577c0eb1e684b76053c56d9523f9aec9cfc652/docs/reference/perl6-documentable-registry.md#method-lookup
    for $registry.lookup(Kind::Routine.gist, :by<kind>).kv -> $k, $v {
        #say "{$k} {$v.name} in {$v.origin.name}";
        %routine-index.push: ($v.name => $v.origin.name);
    }

    %routine-index
}

#| Create a routine index from a given documentation directory $topdir and write
#| it as a json file to the given $file-location
sub write-routine-index-file(
    IO::Path $file-location,
    IO::Path $topdir,
) is export {
    spurt($file-location, to-json(create-routine-index($topdir)))
}

#| Search for a single Routine/Method/Subroutine, e.g. `split`
sub routine-search(
    Str $routine-name,
    IO::Path $routine-index-file
) is export {
    my %routine-index = from-json(slurp($routine-index-file));

    return %routine-index{$routine-name}
}

#| Print the search results. This renders the documentation if `@results == 1`
#| or lists names and associated types if `@results > 1`.
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

#| Print the search results for a routine search. This renders the documentation
#| if `@results == 1` or lists names and associated types if `@results > 1`.
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

# vim: expandtab shiftwidth=4 ft=perl6
