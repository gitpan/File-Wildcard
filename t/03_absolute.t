# -*- perl -*-

# t/03_absolute.t - Absolute file spec test

use strict;
use Test::More;

BEGIN {
    if ($^O =~ /vms/i) {
        plan skip_all => "Cannot test absolute POSIX files on this platform";
    }
    else {
        plan tests => 17;
    }

    #01
    use_ok( 'File::Wildcard' ); 
}

use File::Spec;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;


my $temp = File::Spec->tmpdir.'/File-Wildcard-test';
$temp =~ s!\\!/!g;      # for Windows silly slash direction

# Just in case the temp directory is lying around... 

if (-e $temp) {
    my $wcrm = File::Wildcard->new( path => "$temp///",
                          ellipsis_order => "inside-out");
    for ($wcrm->all) {
        if (-d $_) {
            rmdir $_;
        }
        else {
            1 while unlink $_;
        }
    }
}

mkdir $temp;
mkdir "$temp/abs";
mkdir "$temp/abs/foo";
mkdir "$temp/abs/bar";

open FOO, ">$temp/abs/foo/lish.tmp";
close FOO;
open FOO, ">$temp/abs/bar/drink.tmp";
close FOO;

my $mods = File::Wildcard->new (path => "$temp/abs/foo/lish.tmp",
                               debug => $debug);

#02
isa_ok ($mods, 'File::Wildcard', "return from new");

#03 
like ($mods->next, qr"$temp/abs/foo/lish.tmp"i, 'Simple case, no wildcard');

#04
ok (!$mods->next, 'Only found one file');

$mods = File::Wildcard->new (path => "$temp/abs/*/*.tmp",
                            debug => $debug,
                             sort => 1);

#05
isa_ok ($mods, 'File::Wildcard', "return from new");

my @found = $mods->all;

#06 
is_deeply (\@found, ["$temp/abs/bar/drink.tmp", "$temp/abs/foo/lish.tmp"], 
             'Wildcard in filename');

$mods = File::Wildcard->new (path => "$temp///*.tmp",
                            debug => $debug,
                             sort => 1);

#07
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = $mods->all;

#08 
is_deeply (\@found, ["$temp/abs/bar/drink.tmp", "$temp/abs/foo/lish.tmp"], 
             'Ellipsis found tmp files');

$mods = File::Wildcard->new (path => "$temp///",
                            debug => $debug,
                             sort => 1);

#09
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = $mods->all;

#10 
is_deeply (\@found, [ "$temp/",
                      "$temp/abs/",
                      "$temp/abs/bar/", 
                      "$temp/abs/bar/drink.tmp", 
                      "$temp/abs/foo/",
                      "$temp/abs/foo/lish.tmp",
                    ], 
             'Recursive directory search (normal)');

$mods = File::Wildcard->new (path => "$temp///",
                            debug => $debug,
                             sort => sub { $_[1] cmp $_[0] });

#11
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = $mods->all;

#12 
is_deeply (\@found, [ "$temp/",
                      "$temp/abs/",
                      "$temp/abs/foo/",
                      "$temp/abs/foo/lish.tmp",
                      "$temp/abs/bar/", 
                      "$temp/abs/bar/drink.tmp", 
                    ], 
             'Recursive directory search (custom sort)');

$mods = File::Wildcard->new (path => "$temp///",
                            debug => $debug,
                             sort => 1,
                   ellipsis_order => 'breadth-first');

#13
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = $mods->all;

# Note that breadth-first skips the topmost level
# I have not found an easy way round this.

#14
is_deeply (\@found, [ 
                      "$temp/abs/",
                      "$temp/abs/bar/", 
                      "$temp/abs/foo/",
                      "$temp/abs/bar/drink.tmp", 
                      "$temp/abs/foo/lish.tmp",
                    ], 
             'Recursive directory search (breadth-first)');

$mods = File::Wildcard->new (path => "$temp///",
                            debug => $debug,
                             sort => 1,
                   ellipsis_order => 'inside-out');

#15
isa_ok ($mods, 'File::Wildcard', "(ellipsis) return from new");

@found = $mods->all;

#16 
is_deeply (\@found, [ 
                      "$temp/abs/bar/drink.tmp", 
                      "$temp/abs/bar/", 
                      "$temp/abs/foo/lish.tmp",
                      "$temp/abs/foo/",
                      "$temp/abs/",
                      "$temp/",
                    ], 
             'Recursive directory search (inside-out)');

# Tidy up after tests

for (@found) {
    if (-d $_) {
        rmdir $_;
    }
    else {
        1 while unlink $_;
    }
}

rmdir $temp;

#17
ok(!-e $temp,"Test has tidied up after itself");
