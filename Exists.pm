package Proc::Exists;

use warnings;
use strict;
use vars qw (@ISA @EXPORT_OK $VERSION); 

require Exporter;
use base 'Exporter'; #@ISA = qw(Exporter);
@EXPORT_OK = qw(pexists);

$VERSION = '0.08';

my $use_scalar_pexists = 1;
eval {
	require XSLoader;
	XSLoader::load('Proc::Exists', $VERSION); 
}; if($@) {
	#warn "using pure perl mode, expect degraded performance\n";
	my $pp_pexists = sub {
		my $pid = shift;
		if(kill(0, $pid)) { return 1 }
		else { return ($! =~ m/^
			Operation\s+not\s+permitted | #linux
			Not\s+owner                   #solaris
		$/mx) }
	};
	$use_scalar_pexists = 0;
	*_pexists = \&$pp_pexists; 
}

#last tested version list, ? = not yet tested
# POSIX/UNIX-y OS's are tested both with and without cc
# linuces: {gutsy/amd64|feisty/ppc}, {sarge/2.4/x86|etch/amd64}
#              0.08        0.08          0.08           0.08
# BSDs: FBSD4.11/x86, FBSD6.2/x86, obsd4.2/x86, netbsd3.1/x86
#          0.08           0.08         0.08          ?
# misc: solaris10/x86, osX/ppc, osX/x86, mac OS 9, mac OS 8, mac OS 7
#          0.08           ?        ? 
# win/cygwin/PP:   XP32 XP64 vista vista64 w2k nt4 ws2k3 wCE w95 w98 wme
#                  0.08  ?     ?      ?     ?   ?    ?    ?   ?   ?   ?    
# win/cygwin:      XP32 XP64 vista vista64 w2k nt4 ws2k3 wCE w95 w98 wme
#                  0.08  ?     ?      ?     ?   ?    ?    ?   ?   ?   ?    
# win/strawbery/PP:XP32 XP64 vista vista64 w2k ws2k3
#                  FAIL  ?     ?      ?     ?    ? 
# win/strawberry:  XP32 XP64 vista vista64 w2k ws2k3
#                  0.08  ?     ?      ?     ?    ? 
# win/activestate: XP32 XP64 vista vista64 w2k nt4 ws2k3 wCE w95 w98 wme
#                   ?    ?     ?      ?     ?   ?    ?    ?   ?   ?   ?    
# others? does anyone run perl on VMS, BeOS, RISCOS, Netware3 ?

sub pexists {
	my @pids = @_; 
	my %args = %{ref($pids[-1]) ? pop(@pids) : {}};

	my @results; 
	if(wantarray || !$use_scalar_pexists) {
		foreach my $pid (@pids) {
			my $ret = _pexists($pid); 
#warn "pid: $pid, ret: $ret" if($^O eq "MSWin32");
			die "Proc::Exists - our win32 goop failed us: ret: $ret, pid: $pid - please report this bug" if($ret < 0);
			if($ret) {
				if($args{any}) { return 1; }
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

	* a POSIX-y OS or win32
	* Test::More if you want to run 'make test'


=head1 INCOMPATIBILITIES

There is no pure perl implementation under Windows. However, with
Strawberry Perl L<http://strawberryperl.com/>, this should be less
of an issue.

Any other OS without a POSIX emulation layer will probably be
completely non-functional (unless it implements C<kill()>).

It's possible that if you don't have a C compiler, and you're not
running an obscure UNIX-y OS (read: not linux, *BSD, solaris, or
Mac OS X), you might not pass make test. This is because in
pure-perl mode, we rely on string representation of errno in C<$!>,
which differs from OS to OS. If you find yourself on such a
system, run C<perl -le 'kill 0, 1; print $!'> and please send me
the output at C<< <ski-cpan@allafrica.com> >> with Proc::Exists
in the subject line. Meanwhile you can patch your own source by
adding your string to C<pp_pexists> in C<lib/Proc/Exists.pm>.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  C<< <ski-cpan@allafrica.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Brian Szymanski C<< <ski-cpan@allafrica.com> >>.
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
