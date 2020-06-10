use Rakudoc::Utils;

use Pod::Load;

use Documentable;
use Documentable::Primary;
use Documentable::Registry;

use JSON::Fast;
use Pod::To::Text;

use Path::Finder;

unit module Rakudoc;

constant DOC-SUFFIX = '.pod6';  # As used in the main Raku/doc project

my class X::Rakudoc is Exception {
    has $.message;
    multi method gist(X::Rakudoc:D:) {
        self.message;
    }
}

#| Receive a list of paths to pod files and process them, return an array of
#| processed Documentable objects
sub process-type-pod-files(
    IO::Path @files,
    --> Array[Documentable]
) is export {
    my Documentable @results;

    for @files.list -> $f {
        my $documentable = Documentable::Primary.new(
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
        return ($type-name.IO ~ DOC-SUFFIX).IO
    } else {
        # Replace `::` with the directory separator specific to the
        # platform
        return ($type-name.subst('::', $*SPEC.dir-sep) ~ DOC-SUFFIX).IO;
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
    # In Documentable, the `name` attribute for the Documentable object containing
    # a given routine will only be `routines`, while the actual filename for the
    # independent routines in the Raku documentation is `independent-routines.rakudoc`.
    #
    # For now, this is treated as an edge case here.
    if $search-name eq 'routines' {
        $finder = $finder.name("independent-routines" ~ DOC-SUFFIX);
    } else {
        $finder = $finder.name($search-name ~ DOC-SUFFIX);
    }

    for $finder.in($dir, :file) -> $file {
        @results.push($file);
    }

    @results
}

#| Lookup documentation in association with a type, e.g. `Map`, `Map.new`.
#| The result is an array of Documentable object matching the name.
sub type-search(
    Str $type-name,
    Documentable @documentables,
    Str :$routine?,
    --> Array[Documentable]
) is export {
    my Documentable @results;

    # First, remove elements where name does not match
    @results = @documentables.grep: *.name eq $type-name;

    # If a routine to search for has been provided, we now look for it inside
    # the found types, and return those results instead
    if defined $routine {
        my Documentable @routine-results;

        for @results -> $rs {
            # Loop definitions, look for searched routine
            # `.defs` contains a list of Documentable defined inside a
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

#| Search for all `.rakudoc` files in a given directory (and subdirectories)
sub find-pod-files(
    $dir,
    --> Array[IO::Path]
) is export {
    my IO::Path @results;

    my $finder = Path::Finder;

    $finder = $finder.ext(DOC-SUFFIX);

    for $finder.in($dir, :file) -> $file {
        @results.push($file);
    }

    @results
}

#| Create a routine index for Raku standard documentation.
#| $topdir should be a default topdirectory with the subdirectory
#| 'Type' inside.
#| The resulting index has the routine names as keys, each key harbors
#| an array containing the Types the routine is associated with.
sub create-index(
    @topdirs,
    --> Hash
) is export {
    my %index;

    my Documentable::Registry @registries;

    for @topdirs».Str -> $topdir {
        my $registry = Documentable::Registry.new(
            # `Documentable::Registry`'s $topdir attribute takes a string instead
            # of an `IO::Path` currently.
            :$topdir,
            :dirs(['Type']),
            :!verbose,
            :!use-cache,
        );
        $registry.compose;

        @registries.push($registry);
    }

    for @registries -> $registry {
        for $registry.lookup(Kind::Routine, :by<kind>).list {
            #say "{.name} in {.origin.name}";
            %index.push: .name => .origin.name;
        }
    }

    %index
}

#| Create a routine index from a given documentation directory $topdir and write
#| it as a json file to the given $file-location
sub write-index-file(
    IO::Path $file-location,
    *@topdirs,
) is export {
    spurt($file-location, to-json(create-index(@topdirs)))
}

#| Search for a single Routine/Method/Subroutine, e.g. `split`
sub routine-search(
    Str $routine-name,
    IO::Path $index-file
) is export {
    my %index = from-json(slurp($index-file));

    return %index{$routine-name} // Empty
}

#| Print the search results. This renders the documentation if `@results == 1`
#| or lists names and associated types if `@results > 1`.
#| $use-pager enables/disables the usage of the system pager
sub show-t-search-results(Documentable @results, :$use-pager) is export {
    if @results.elems == 1 {
        if $use-pager {
            # Use `less` on Linux, and `more` on windows
            my $pager = %*ENV<PAGER> // ($*DISTRO.is-win ?? 'more' !! 'less');

            shell("cat <<'RAKUDOC_HACK_END' | $pager\n{pod2text(@results.first.pod)}\nRAKUDOC_HACK_END");
        } else {
            say pod2text(@results.first.pod);
        }
    } elsif @results.elems < 1 {
        X::Rakudoc.new(:message("No matches in [{get-doc-locations.join(', ')}]")).throw;
    } else {
        say 'Multiple matches:';
        for @results -> $r {
            say "    {$r.subkinds} {$r.name}";
        }
    }
}

#| Load pods from a `.rakudoc` file, convert and return them as txt.
#| If the file is a multiclass file, the returning string will
#| contain every pod.
sub load-pod-to-txt(
    IO::Path $pod-file,
    --> Str
) is export {
    my Str $txt;
    my @loaded-pods = load($pod-file);

    for @loaded-pods -> $lp {
        $txt ~= pod2text($lp);
    }

    $txt
}

# vim: expandtab shiftwidth=4 ft=raku
