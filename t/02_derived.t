# -*- perl -*-

# t/02_derived.t - Wildcards with captures

use strict;
use Test::More tests => 3;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok( 'File::Wildcard' ); }

my $mods = File::Wildcard->new (path => '\.(///)(\w*)\.pm',
                              derive => [ '$1$2.tmp' ],
                               debug => $debug);

#02
isa_ok ($mods, 'File::Wildcard', "return from new");

my @found = sort {$a->[0] cmp $b->[0]} $mods->all;

#03 
is_deeply (\@found, [ [ qw( blib/lib/File/Wildcard.pm blib/lib/File/Wildcard.tmp ) ],
                      [ qw( lib/File/Wildcard.pm lib/File/Wildcard.tmp)]], 
             'Returned expected derived list');

