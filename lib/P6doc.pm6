unit module P6doc;

use JSON::Fast;
use File::Find;

constant DEBUG      = %*ENV<P6DOC_DEBUG>;
constant INTERACT   = %*ENV<P6DOC_INTERACT>;

# die with printing a backtrace
my class X::P6doc is Exception {
    has $.message;
    multi method gist(X::P6doc:D:) {
        self.message;
    }
}

sub findbin() returns IO::Path is export {
    $*PROGRAM.parent;
}

sub build_index(IO::Path $index) is export {
    my %words;

    # XXX should index more than this - currently only core pod
	# NOTE: Temporarily use the doc folder relative to the Current
	#       Working Directory $*CWD instead of using
	#       $*REPO.repo-chain() to find it, for easier testing.
	my @locations = ($*CWD>>.add: 'doc').grep: *.IO.d;
	#my @locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;

    for @locations -> $lib_path is copy {
        # for p6doc -f only looking under "Type" directory is useful (and faster)
        my @files = find(:dir($lib_path.IO.add("Type")),:type('file'));

        for @files -> $f {
            my $file = $f.path;
            next if $file !~~ /\.pod6?$/;
            my $pod = substr($file.Str, 0 , $file.Str.chars -4);
            $pod.=subst($lib_path,"");
            $pod.=subst(/"{$*SPEC.dir-sep}"/,'::',:g);
            my $section = '';
            for open( $file.Str).lines -> $row {
                if $row ~~ /^\=(item|head\d) \s+ (.*?) \s*$/ {
                    $section = $1.Str if $1.defined;
                    %words{$section}.push([$pod, $section]) if $section ~~ m/^("method "|"sub "|"routine ")/;
                }
            }
        }
    }

    my $out = open($index, :w);
    $out.print(%words.perl);
    $out.close;
}

sub search-paths() returns Seq is export {
    (('.', |$*REPO.repo-chain())>>.Str X~ </doc/>).grep: *.IO.d
}

sub module-names(Str $modulename) returns Seq {
    $modulename.split('::').join('/') X~ <.pm .pm6 .pod .pod6>;
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

# Also see
# https://github.com/perl6/doc/blob/master/lib/Pod/To/SectionFilter.pm6
sub get-docs(IO::Path $path, :$section, :$package is copy) is export {
	if (is-pod($path)) eq False {
		say "No Pod found in $path";
		return
	}

	if $section.defined {
		%*ENV<PERL6_POD_HEADING> = $section;
		my $i = findbin().add('../lib');
		run($*EXECUTABLE, "-I$i", "--doc=SectionFilter", $path);
	} else {
		run($*EXECUTABLE, "--doc", $path);
	}
}

sub show-docs(Str $path, :$section, :$no-pager, :$package is copy) is export {
    my $pager;
    $pager = %*ENV<PAGER> // ($*DISTRO.is-win ?? 'more' !! 'less -r') unless $no-pager;
    if not open($path).lines.grep( /^'=' | '#|' | '#='/ ) {
        say "No Pod found in $path";
        return;
    }
    my $doc-command-str = $*EXECUTABLE-NAME;
    if $section.defined {
        %*ENV<PERL6_POD_HEADING> = $section;
        my $i = findbin() ~ '../lib';
        $doc-command-str ~= " -I$i --doc=SectionFilter"
    } else {
        $doc-command-str ~= " --doc"
    }
    $doc-command-str ~= " $path ";
    if $package.DEFINITE {
        my $cs = ";";
        $cs = "&" if $*DISTRO.is-win;
        $package ~~ s/"Type::"//;
        $doc-command-str = "echo \"In {$package}\"$cs" ~ $doc-command-str;
    }
    $doc-command-str ~= " | $pager" if $pager;
    say "launching '$doc-command-str'" if DEBUG;
    shell $doc-command-str;
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
        say "No documentation found for a routine named '$docee'";
        exit 2;
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
        note "No such type '$module'";
        exit 1;
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

# vim: expandtab shiftwidth=4 ft=perl6
