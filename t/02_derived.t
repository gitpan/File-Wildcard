# -*- perl -*-

# t/02_derived.t - Wildcards with captures

use strict;
use Test::More tests => 6;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok( 'File::Wildcard' ); }

my $mods = File::Wildcard->new (path => './//*.pm',
                              derive => [ '$1/$2.tmp' ],
                               debug => $debug);

#02
isa_ok ($mods, 'File::Wildcard', "return from new");

my @found = sort {$a->[0] cmp $b->[0]} $mods->all;

#03 
is_deeply (\@found, [ [ qw( blib/lib/File/Wildcard.pm blib/lib/File/Wildcard.tmp ) ],
                      [ qw( lib/File/Wildcard.pm lib/File/Wildcard.tmp)]], 
             'Returned expected derived list');

$mods = File::Wildcard->new( path => 'lib/File/Wild????.*',
                           derive => [ 'Playing$1.$2' ],
                            debug => $debug );

#04
isa_ok ($mods, 'File::Wildcard', "return from new");

#05
is_deeply ($mods->next, [qw( lib/File/Wildcard.pm Playingcard.pm )],
             'Multiple patterns in the same component');

#06
ok(!$mods->next, 'Only one match');
