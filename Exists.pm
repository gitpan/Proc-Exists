package Proc::Exists;

BEGIN { eval { require warnings; }; }; #it's ok if we can't load warnings
use strict;
use vars qw (@ISA @EXPORT_OK $VERSION); 

require Exporter;
use base 'Exporter';
@EXPORT_OK = qw(pexists);

$VERSION = '0.12';

my $use_scalar_pexists = ($^O ne 'MSWin32');

eval {
	require XSLoader;
	XSLoader::load('Proc::Exists', $VERSION); 
}; if($@) {
	#warn "using pure perl mode, expect degraded performance\n";
	my %eperm_strings = ( solaris => 'Not\s+owner' );
	for my $os ( qw (linux freebsd openbsd netbsd darwin cygwin) ) {
		$eperm_strings{$os} = 'Operation\s+not\s+permitted';
	}
	my $eperm_str = $eperm_strings{$^O};
	#the linux-y case is more common... here's hoping...
	if(!defined($eperm_str)) {
		require Config;
		my $archname = $Config::Config{archname}; 
		my $osvers = $Config::Config{osvers}; 
		$eperm_str = 'Operation\s+not\s+permitted';
		warn "unknown OS in pureperl mode, you may encounter unexpected results!\n";
		warn "please follow the instructions in the INCOMPATIBILITIES section of the perldoc\n";
		warn "osname: $^O\narchname: $archname\nosvers: $osvers\n"; 
	}
	my $eperm_re = qr/^\s*$eperm_str\s*$/; 

	my $pp_pexists = sub {
		my $pid = shift;
		if (kill 0, $pid) { return 1 }
		else              { return ($! =~ /$eperm_re/) };
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
or Mac OS X), you might not pass make test. This is because in
pure-perl mode, we rely on string representation of errno in C<$!>,
which differs from OS to OS. If you find yourself on such a
system, don't fret! First, find the PID of a process running as
another user (in almost all cases, init will be running as root
with PID 1). Then run: C<perl -le 'kill(0,PID);print $^O.": $!"'>
(substituting your PID). You can use this string to patch your
source by adding it to %eperm_strings circa line 20 of Exists.pm,
and please tell me what you did at B<< <ski-cpan@allafrica.com> >>
(making sure to include Proc::Exists in the subject line) so I can
include your patch in the next release. If this procedure fails, please 
send the output of misc/gather-info.pl to
B<< <ski-cpan@allafrica.com> >> and I'll try to send you a patch
as soon as I can. Again, be sure to put Proc::Exists in the subject 
line. Note that a signal 0 sent by kill only indicates if a signal may 
be sent, it does not actually send any signal, and so will not disrupt 
any process.

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
