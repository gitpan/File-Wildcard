# -*- perl -*-

# t/03_absolute.t - Absolute file spec test

use strict;
use Test::More tests => 10;
use File::Spec;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok( 'File::Wildcard' ); }

my $temp = File::Spec->tmpdir.'/File-Wildcard-test';
$temp =~ s!\\!/!g;      # for Windows silly slash direction

if (-e $temp) {
    my $wcrm = File::Wildcard->new( path => "$temp///");
    for (reverse sort $wcrm->all) {
        1 while unlink $_;
    }
}

mkdir $temp;
mkdir "$temp/abs";

open FOO, ">$temp/abs/foo.tmp";
close FOO;
open FOO, ">$temp/abs/bar.tmp";
close FOO;

my $mods = File::Wildcard->new (path => "$temp/abs/foo.tmp",
                               debug => $debug);

#02
isa_ok ($mods, 'File::Wildcard', "return from new");

#03 
like ($mods->next, qr"$temp/abs/foo.tmp"i, 'Simple case, no wildcard');

#04
ok (!$mods->next, 'Only found one file');

$mods = File::Wildcard->new (path => "$temp/abs/*.tmp",
                            debug => $debug);

#05
isa_ok ($mods, 'File::Wildcard', "return from new");

my @found = sort $mods->all;

#06 
is_deeply (\@found, ["$temp/abs/bar.tmp", "$temp/abs/foo.tmp"], 
             'Wildcard in filename');

$mods = File::Wildcard->new (path => "$temp///*.tmp",
                            debug => $debug);

#07
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = sort $mods->all;

#08 
is_deeply (\@found, ["$temp/abs/bar.tmp", "$temp/abs/foo.tmp"], 
             'Ellipsis found tmp files');

$mods = File::Wildcard->new (path => "$temp///",
                            debug => $debug);

#09
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = sort $mods->all;

#10 
is_deeply (\@found, [ "$temp/",
                      "$temp/abs/",
                      "$temp/abs/bar.tmp", 
                      "$temp/abs/foo.tmp"], 
             'Recursive directory search');

# Tidy up after tests

for (reverse @found) {
    if (-d $_) {
        rmdir $_;
    }
    else {
        1 while unlink $_;
    }
}

rmdir $temp;
