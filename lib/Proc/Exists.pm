package Proc::Exists;

use warnings;
use strict;
use vars qw (@ISA @EXPORT_OK $VERSION); 

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(pexists);

$VERSION = '0.03';

eval {
	require XSLoader;
	XSLoader::load('Proc::Exists', $VERSION); 
}; if($@) {
	*_pexists = \&pp_pexists;
	#warn "using pure perl mode, expect degraded performance\n";
}

sub pp_pexists {
	my $pid = shift;
	if(kill(0, $pid)) { return 1 }
	else { return ($! =~ /^
		Operation\s+not\s+permitted | #linux
		Not\s+owner                   #solaris
	/x) }
}

#0.03 testing:
# linuces: {gutsy/amd64|feisty/ppc}, {sarge/2.4/x86|etch/amd64}, (need rpm-ers)
#               ok         ok            ok             ok 
# BSDs: FBSD4.11/x86, FBSD6.2/x86, obsd4.0/x86, netbsd3.1/x86
#            ok            ok            ?           ?
# misc: solaris10/x86, osX/ppc, osX/x86, windows, MacOS9
#           ok            ?        ?       no       ?
# exotic: VMS, BeOS, RISCOS, Netware3, ...

sub pexists {
	my @pids = @_; 
	my %args = %{ref($_[-1]) ? pop(@pids) : {}};

	my @results; 
	foreach my $pid (@pids) {
		if(_pexists($pid)) {
			if($args{any}) { return 1; }
			push @results, $pid; 
		} elsif($args{all}) {
			return 0;
		}
	}
	return wantarray ? @results : scalar @results; 
}

1;
__END__

=head1 NAME

Proc::Exists - quickly check for process existence


=head1 VERSION

This document describes Proc::Exists version 0.03


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
same owner. Currently implemented via sending a 0 (test) signal to
the pid of the process to check and examining the result, which is
POSIX-blessed.


=head1 DEPENDENCIES

	* a POSIX-y OS
	* Test::More if you want to run 'make test'


=head1 INCOMPATIBILITIES

Windows, and Mac OS 9 and under probably doesn't work. There are 
probably others - but any POSIX-y OS will be fine.

Also, if you don't have a C compiler, and you're not running linux, 
Solaris, or FreeBSD, you might not pass make test. This is because
in pure-perl mode, we rely on string representation of errno in
$!, which differs from OS to OS. If you find yourself on such a
system, run "perl -le 'kill 0, 1; print $!'" and please send me
the output at C<< <ski-cpan@allafrica.com> >> with Proc::Exists
in the subject line. Meanwhile you can patch your own source by
adding your string to pp_pexists in lib/Proc/Exists.pm.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  C<< <ski-cpan@allafrica.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Brian Szymanski C<< <ski-cpan@allafrica.com> >>. All rights reserved.

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
