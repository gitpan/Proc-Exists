package Proc::Exists;

#use warnings; #it's ok if we can't load warnings, but the author should
use strict;
use Proc::Exists::Configuration;
use vars qw (@ISA @EXPORT_OK $VERSION); 

require Exporter;
use base 'Exporter';
@EXPORT_OK = qw(pexists);

$VERSION = '0.15';

my $use_scalar_pexists = ($^O ne 'MSWin32');

eval {
	require XSLoader;
	XSLoader::load('Proc::Exists', $VERSION); 
}; if($@) {
	#warn "using pure perl mode, expect degraded performance\n";
	my $EPERM = $Proc::Exists::Configuration::EPERM; 
	my $ESRCH = $Proc::Exists::Configuration::ESRCH; 
	my $pp_pexists = sub {
		my $pid = $_[0]; 
		if (kill 0, $pid) {
			return 1;
		} else {
			if($! == $EPERM) {
				return 1;
			} elsif($! == $ESRCH) {
				return 0;
			} elsif($^O eq "MSWin32") {
				die "can't do pure perl on MSWin32 - \$!: (".(0+$!)."): $!"; 
			} else {
				die "unknown numeric \$!: (".(0+$!)."): $!, pureperl, OS: $^O"; 
			}
		}
	};
	$use_scalar_pexists = 0;
	*_pexists = \&$pp_pexists; 
}

sub pexists {
	my @pids = @_; 
	my %args = %{ref($pids[-1]) ? pop(@pids) : {}};

	my @results; 
	if(wantarray || !$use_scalar_pexists) {
		foreach my $pid (@pids) {
			die "got non-integer pid: $pid" if($pid !~ /^\d+$/); 
			my $ret = _pexists($pid); 
			if($ret < 0) {
				$ret += 2;
				#TODO: better error message here
				warn "windows ignored the bottom 2 bits of the pid $pid, unexpected results may occur!";
			}
			if($ret) {
				return 1 if($args{any}); 
				push @results, $pid; 
			} elsif($args{all}) {
				return 0;
			}
		}
		return wantarray ? @results : scalar @results; 
	} else {
		return _scalar_pexists([@pids], $args{any} || 0, $args{all} || 0);
	}
}

1;
__END__

=head1 NAME

Proc::Exists - quickly check for process existence


=head1 VERSION

This document describes Proc::Exists


=head1 SYNOPSIS

   use Proc::Exists qw(pexists);

   my $dead_or_alive       = pexists($pid); 
   my @survivors           = pexists(@pid_list); 
   my $nsurvivors          = pexists(@pid_list); 
   my $at_least_one_lived  = pexists(@pid_list, {any => 1});
   my $all_pids_lived      = pexists(@pid_list, {all => 1});

  
=head1 FUNCTIONS

=head2 pexists( @pids, [ $args_hashref ] )

Supported arguments are 'any' and 'all'. See details above.


=head1 DESCRIPTION

A simple and fast module for checking whether a process exists or
not, regardless of whether it is a child of this process or has the
same owner. 

On POSIX systems, this is implemented by sending a 0 (test) signal to
the pid of the process to check and examining the result and errno.


=head1 DEPENDENCIES

 * any os with a POSIX layer or win32
 * Test::More if you want to run 'make test'


=head1 INCOMPATIBILITIES

It's possible that if you don't have a C compiler, and you're
running an "obscure" UNIX-y OS (read: not linux, *BSD, solaris,
or Mac OS X), you might not pass make test. This is because we need
to compare the value of $! after a call to kill() with EPERM
and ESRCH. Not wanting to rely on POSIX, we determine EPERM 
and ESRCH at build (Makefile.PL) time, by using POSIX if it exists
-- but using the common values of EPERM==1 and ESRCH==3 if we can't 
load POSIX. If you find yourself on such a system, your best bet is to 
look up EPERM and ESRCH (try grepping for them down /usr/include or 
wherever your headers are kept). If you get hits back, you can edit 
Exists/Configuration.pm and add your values there, and re-run the build 
process. Whether you were successful or not, please send a description
of what you tried, as well as the output of perl -V and the results of 
perl misc/gather-info.pl to B<< <ski-cpan@allafrica.com> >> - making
sure to include Proc::Exists in the subject line (or else I won't read 
it!) If you had no success, hopefully I'll be able to provide a patch 
for you, and a fix/workaround for the next release of Proc::Exists. By 
the way, don't be afraid that we send signal 0 to your processes - kill 
with signal 0 only indicates if a signal may be sent, it does not 
actually send any signal, and so will not disrupt any process.

There is no pure perl implementation under Windows. The solution
is to use Strawberry Perl L<http://strawberryperl.com/>.

Any other OS without a POSIX emulation layer will probably be
completely non-functional (unless it implements C<kill()>).


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put 
Proc::Exists in the subject line if you want me to read your message.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Brian Szymanski B<< <ski-cpan@allafrica.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
