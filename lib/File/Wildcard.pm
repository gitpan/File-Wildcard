
package File::Wildcard;
use strict;

our $VERSION = 0.01;

=head1 NAME

File::Wildcard - Enhanced glob processing

=head1 SYNOPSIS

  use File::Wildcard;
  my $foo = File::Wildcard->new(path => "/home/me///core");
  while (my $file = $foo->next) {
     unlink $file;
  }
  
=head1 DESCRIPTION

When looking at how various operating systems do filename wildcard expansion
(globbing), VMS has a nice syntax which allows expansion and searching of
whole directory trees. It would be nice if other operating systems had 
something like this built in. The best Unix can manage is through the
utility program C<find>.

This module provides this facility to Perl. Whereas native VMS syntax uses
the ellipsis "...", this will not fit in with POSIX filenames, as ... is a
valid (though somewhat strange) filename. Instead, the construct "///" is
used as this cannot syntactically be part of a filename, as you do not get
three concurrent filename separators with nothing between.

The module also takes B<regular expressions> in any part of the wildcard
string between slashes, and can bind a series of back references ($1, $2
etc.) which are available to construct new filenames.



=head2 new

C<File::Wildcard->new( $wildcard, [,option => value,...]);>

  my $foo = File::Wildcard->new( path => "/home/me///core");
  my $srcfnd = File::Wildcard->new( path => "src///(.*)\.cpp",
               derive => ["src/$1/$2.o","src/$1/$2.hpp"]);

This is the constructor for File::Wildcard objects. At a simple level,
pass a single wildcard string. For more complicated operations, you can
use the derive option to specify regular expression captures to form 
the basis of other filenames that are constructed for you.

The $srcfnd example gives you object files and header files corresponding
to C++ source files.

Here are the options that are available:

=over 4
=item *
B<derive>: supply an arrayref with a list of derived filenames, which
will be constructed for each matching file.
=item *
B<follow>: if given a true value indicates that symbolic links are to be
followed.

=back

=head2 next

  while (my $core = $foo->next) {
      unlink $core;
  }
  my ($src,$obj,$hdr) = $srcfnd->next;

The C<next> method is an iterator, which returns successive files. Scalar
context can be used in the case of a simple find. If more than one spec was
passed to new, these files are constructed and returned as a list. There is
no check that these files actually exist.

Note that C<next> maintains an internal cursor, which retains context and
state information. Beware if the contents of directories are changing while
you are iterating with next; you may get unpredictable results. If you are
changing the contents of the directories you are scanning, you are better
off slurping the whole tree with C<all>.

=head2 all

  my @cores = $foo->all;

C<all> returns an array of matching files, in the simple case. Returns an
array of arrays if you are constructing new filenames, like the $srcfnd
example.

Beware of the performance and memory implications of using C<all>. The
method will not return until it has read the entire directory tree.

=head2 reset

C<reset> causes the wildcard context to be set to re-read the first filename
again. Note that this will cause directory contents to be re-read.

=head2 close

Release all directory handles associated with the File::Wildcard object.
An object that has been closed will be garbage collected once it goes out
of scope. Wildcards that have been exhausted are automatically closed, 
(i.e. C<all> was used, or c<next> returned undef).

Subsequent calls to C<next> will return undef. It is possible to call 
C<reset> after C<close> on the same File::Wildcard object, which will cause 
it to be reopened.

=head1 CAVEAT

This module takes POSIX filenames, which use forward slash '/' as a
path separator. All operating systems that run Perl can manage this type
of path. The module is not designed to work with B<native> file specs.
If you want to write code that is portable, convert native filespecs to
the POSIX form. There is of course no difference on Unix platforms.
  
=head1 BUGS

Please report bugs to http://rt.cpan.org

=head1 SUPPORT

This is an Alpha release. Also note that I am supporting it in my unpaid
spare time.

=head1 AUTHOR

	Ivor Williams
	ivorw-file-wildcard@xemaps.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

glob(3), L<File::Find>.

=cut

use Params::Validate qw(:all);
use Carp;

sub new {
    my $pkg = shift;

    my %par = validate( @_,
        { derive => 0,
          follow => 0,
          absolute => 0,
          debug => 0,
          path => { type => SCALAR },
        } );

    $par{path} =~ s!///!//!g;
    $par{absolute} = $par{path} =~ s!^/!!;
    $par{path} =~ s!^\\.(\W)!$1!;
    my $pathre = $par{path} . '$';
    $pathre =~ s!//!.*?!g;
    $pathre = '^'.$pathre if $par{absolute};
    $par{path_regexp} = qr($pathre);
    $par{path} =~ s!(^|/)(\\./)+!$1!g;
    1 while $par{path} =~ s/\(([^()?][^()]*)\)/$1/;
    my @chunks = split m(/),$par{path};
    shift @chunks if $chunks[0] eq '';
    $par{path} = \@chunks;
    
    bless \%par, $pkg;
}

sub next {
    my $self = shift;

    $self->_set_state( state => 'initial') unless exists $self->{state};

    while (!exists $self->{retval}) {
        print STDERR "In state ".$self->{state}."\n" if $self->{debug};
        my $method = "_state_" . $self->{state};
        $self->$method;
    }
    print STDERR "Returned ".($self->{retval} || 'undef')."\n"
        if $self->{debug};
    my $rv = $self->{retval};
    delete $self->{retval};

    $rv;
}

sub all {
    my $self = shift;

    my @out;

    while (my $match = $self->next) {
        push @out, $match;
    }

    @out;

}

sub close {
    my $self = shift;

    delete $self->{stack};
    delete $self->{dir};
    $self->_set_state( state => 'finished');
}

sub reset {
    my $self = shift;

    $self->close;
    $self->_set_state( state => 'initial');
}

sub derived {
    my $self = shift;

    return $self->{resulting_path} unless exists $self->{derive};

    my @out = ($self->{resulting_path});
    my $re = $self->{path_regexp};
    $self->{resulting_path} =~ /$re/;
    for (@{$self->{derive}}) {
        push @out,eval(qq("$_"));
    }

    \@out;
}

sub _set_state {
    my $self = shift;

    my %par = validate( @_ , {
                state => { type => SCALAR },
                dir => { type => GLOBREF, optional => 1 },
                wildcard => 0,
                } );
    $self->{$_} = $par{$_} for keys %par;
}

sub _push_state {
    my $self = shift;

    print STDERR "Push state: resulting_path: ".
           $self->{resulting_path}.
           " Wildcard: " . $self->{wildcard} .
           " path_remaining: ".
           join ('/',@{$self->{path_remaining}}). "\n"
           if $self->{debug};
    push @{$self->{state_stack}}, { map { $_, 
          (ref($self->{$_}) eq 'ARRAY') ? [@{$self->{$_}}] : $self->{$_} }
          qw/ state path_remaining dir resulting_path / } ;
}

sub _pop_state {
    my $self = shift;

    my $newstate = pop @{$self->{state_stack}} 
                       or carp "State stack exhausted";
    $self->{$_} = $newstate->{$_} for keys %$newstate;
    print STDERR "Pop state to ".$self->{state}.
          " resulting_path: ".
           $self->{resulting_path}.
           " Wildcard: " . $self->{wildcard} .
           " path_remaining: ".
           join ('/',@{$self->{path_remaining}}). "\n"
           if $self->{debug};
}

sub _state_initial {
    my $self = shift;

    $self->{resulting_path} = $self->{absolute} ? '/' : '';
    $self->{path_remaining} = [ @{$self->{path}} ];
    #my $re = join '/', @{$self->{path}};
    #$re =~ s!/(/|$)!/(.*?)!;
    #$self->{path_regexp} = qr($re);

    $self->_set_state ( state => 'finished');
    $self->_push_state;
    $self->_set_state ( state => 'nextdir');
}

sub _state_finished {
    my $self = shift;
    
    $self->{retval} = undef;   # Autovivification optimises this away :(
}

sub _state_nextdir {
    my $self = shift;

    unless (@{$self->{path_remaining}}) {
        my $re = $self->{path_regexp};
        $self->{retval} = $self->derived 
            if $self->{resulting_path} =~ /$re/;
        $self->_pop_state;
        return;
    }

    my $pathcomp = shift @{$self->{path_remaining}};

    if ($pathcomp =~ /^([\w_ &-]|\\.)+$/) {
        $pathcomp =~ s/\\(.)/$1/g;
        $self->{resulting_path} .= $pathcomp;
        $self->{resulting_path} .= '/' if @{$self->{path_remaining}};
    }
    elsif ($pathcomp eq '') {
#        unshift @{$self->{path_remaining}}, $pathcomp;
        $self->_set_state( state => 'ellipsis');
        $self->_push_state;
        $self->_set_state( state => 'nextdir' );
    }
    else {
        my $wcdir;
        opendir $wcdir,$self->{resulting_path} || '.';
        $self->_set_state( state => 'wildcard', 
                             dir => $wcdir, 
                        wildcard => $pathcomp);
    }
}

sub _state_wildcard {
    my $self = shift;

    my $fil = '.';
    while (($fil eq '.') || ($fil eq '..')) {
        $fil = readdir $self->{dir};
        return $self->_pop_state unless defined $fil;
    }
    $self->_push_state;
    $fil =~ s/\./\\./g;
    unshift @{$self->{path_remaining}}, $fil;
    $self->_set_state ( state => 'nextdir' );
}

sub _state_ellipsis {
    my $self = shift;

    unshift @{$self->{path_remaining}}, '.*', '';
    $self->_set_state( state => 'nextdir' );
}

1; #this line is important and will help the module return a true value
__END__

