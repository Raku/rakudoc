# perl6-p6doc [![Build Status](https://travis-ci.org/noisegul/perl6-p6doc.svg?branch=master)](https://travis-ci.org/noisegul/perl6-p6doc)

The `p6doc` command line tool, improved!

## Prerequisites

- Linux
- Rakudo 2019.03
- zef 0.7.4

## Installation

Clone the repository, the testdata is included as a submodule:

```
git clone --recurse-submodules https://github.com/noisegul/perl6-p6doc
```

If you already `git clone`'d it, you can get the submodule afterwards like this:

```
git submodule update --init --recursive
```

Until Perl6::Documentable is released and integrated into the ecosystem, manual
installation is recommended:

```
zef install https://github.com/antoniogamiz/Perl6-Documentable/archive/v2.1.3.tar.gz
```

Then install only the remaining dependencies for `p6doc`:

```
$ zef --depsonly install ./perl6-p6doc
```

## Trying it out with the test-docs

From inside the repository, you can try out `p6doc` using the testdata, be aware
that the test-docs obviously only include the minimum, and are primarily designed to
test correct POD parsing, so they don't necessarily represent actual documentation.

Type searching:
```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Map
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Map.new
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Array
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Cool.abs
```

Searching for single routines:

First build the index.
```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -b
```

Use -r to search for a single routine:

```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -r=new
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -r=abs
```

The usage of the test-data is toggled using the environment variable
`P6DOC_TEST`, the example sets it temporarily, this might work different
on other shells than `bash`.

### Trying it out with the full documentation

p6doc can theoretically already be used with system installed docs in place
of the 'old' p6doc, searching for system installed documentation is the default
behaviour. However be aware that Perl6::Documentable, and through that p6doc
require the updated POD format, as found in the current master branch of perl6/doc.

If you try it out with the currently released set of docs as they
are distributed with Rakudo Star 2019.03 for example, you might
encounter an error like the following:

```
kind not found in Path pod file config.
The first line of the pod should contain:
=begin pod :kind('<value>') :subkind('<value>') :category('<value')
```

Also there might still be problems with clashing dependency versions and
module names with Perl6::Documentable when using Rakudo Star, so it's
not recommended.

### Manually specifying a directory

To still try out `p6doc` with the full set of documentation, it is also possible
to manually specify a directory with `-d`. First grab the
documentation from perl6/doc, for example by cloning the whole repository:

```
git clone https://github.com/perl6/doc
```

The relevant folder is the `doc` folder inside that repository (which is also
named doc).
So if you cloned both this repository, and the perl6/doc repository

```
perl6-repositories/
├── doc
└── perl6-p6doc
```

you can use it like in the following examples:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc IO
$ perl6 -Ilib bin/p6doc -d=../doc/doc Num
$ perl6 -Ilib bin/p6doc -d=../doc/doc Num.rand
$ perl6 -Ilib bin/p6doc -d=../doc/doc IO::Path::Unix
$ perl6 -Ilib bin/p6doc -d=../doc/doc Proc::Async.stdout
```

For routine searching, first build the index for that directory:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc -b
```

Then search for single routines in the given directory:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc -r=say
$ perl6 -Ilib bin/p6doc -d=../doc/doc -r=exit
```
