# -*- perl -*-

# t/01_basic.t - basic tests

use strict;
use Test::More tests => 14;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok( 'File::Wildcard' ); }

my $mods = File::Wildcard->new (path => 'lib/File/Wildcard.pm',
                               debug => $debug);

#02
isa_ok ($mods, 'File::Wildcard', "return from new");

#03 
like ($mods->next, qr'lib/File/Wildcard.pm'i, 'Simple case, no wildcard');

#04
ok (!$mods->next, 'Only found one file');

$mods = File::Wildcard->new (path => 'lib/File/Wildcard.*', 
                            debug => $debug);

#05
isa_ok ($mods, 'File::Wildcard', "return from new");

#06 
like ($mods->next, qr'lib/File/Wildcard\.pm'i, 'Simple asterisk');

#07
ok (!$mods->next, 'Only found one file');

$mods = File::Wildcard->new (path => 'lib/File/Wild????.pm',
                            debug => $debug);

#08
isa_ok ($mods, 'File::Wildcard', "return from new");

#09
like ($mods->next, qr'lib/File/Wildcard\.pm'i, 'single char wildcards');

#10
ok (!$mods->next, 'Only found one file');

$mods = File::Wildcard->new (path => 'lib/F*/Wildcard.pm',
                            debug => $debug);

#11
isa_ok ($mods, 'File::Wildcard', "return from new");

my @found = $mods->all;

#12 
is_deeply (\@found, [qw( lib/File/Wildcard.pm )], 
             'Wildcard further back in path');

$mods = File::Wildcard->new (path => './//Wildcard.pm',
                            debug => $debug);

#13
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = sort $mods->all;

#14 
is_deeply (\@found, [qw( blib/lib/File/Wildcard.pm lib/File/Wildcard.pm )], 
             'Ellipsis found blib and lib modules');


