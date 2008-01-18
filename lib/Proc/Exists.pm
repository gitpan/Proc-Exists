package Proc::Exists;

use warnings;
use strict;

$Proc::Exists::VERSION = '0.01';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(pexists);

#0.01 testing:
# linuces: {gutsy|gutsy-mtab|feisty}, {sarge/2.4|etch}
#             ok      ok       ok         ok      ok
# FBSD 4.11/6.2, obsd4.0, netbsd3.1, solaris 10, mac os X, windows
#       ok   ok     ?        ?           ok        ?         ?

my $supported; 
sub supported {
	#have we already checked?
	return $supported if(defined($supported)); 

	#fastest way to determine mounts is via /etc/mtab on linux
	my (@mounts, $re); 
	if(open(my $mtab, "<", "/etc/mtab")) {
		@mounts = grep { /^(none|proc)\s+\S+\s+proc/ } <$mtab>; 
		close($mtab);
	#invoke mount if no /etc/mtab (presumably non-linux)
	} elsif(my $mount = `which mount`) {
		#everybody is special! so many special formats! awesome!
		@mounts = grep { m{^
			(	\S+\s+on\s+proc |          #solaris: /proc on proc
				(linprocfs|procfs)\s+on |  #freebsd: (linprocfs|procfs) on /proc
				#linux: (proc|none) on /proc type proc
				(proc|none)\s+on\s+\S+\s+type\s+proc
			) }x } `$mount`; 
	}

	if(@mounts) {
		my $mount = $mounts[0];
		#no matter the format, the word with a leading slash is our path.
		#so, split the first 3 words off, chuck the remainder, and take
		#the first word with a leading slash to be our path
		$mount = (grep { /^\// } (split(/\s+/, $mount, 4))[0..3])[0];
		if($mount) {
			$supported = "procfs:$mount"; 
			$Proc::Exists::pexists_sub = sub { return (-d "$mount/".$_[0]) };
			return $supported; 
		}
	#we should have a ps binary even if /proc isn't mounted
	} elsif(my $ps = `which ps`) {
		#TODO: parse ps auxww or ps ef or something like it
	} else {
		#TODO: other tests
	}

	return;
}

#TODO: generate pexists, not just pexists_sub, at
#      supported() / first call time
sub pexists {
	my @pids = @_; 
	my %args = %{ref($_[-1]) ? pop(@pids) : {}};

	#first call to pexists, and we haven't yet called supported()
	if(!defined($Proc::Exists::pexists_sub)) {
		die "unsupported system" unless supported();
	}

	my @results; 
	foreach my $pid (@pids) {
		if($Proc::Exists::pexists_sub->($pid)) {
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

This document describes Proc::Exists version 0.0.1


=head1 SYNOPSIS

   use Proc::Exists qw(pexists);

	#optionally, check for system support (if you don't, this check
	#will happen during your first pexists() call)
   Proc::Exists::supported() || die "/proc filesystem not detected";

   my $dead_or_alive       = pexists($pid); 
   my @survivors           = pexists(@pid_list); 
   my $nsurvivors          = pexists(@pid_list); 
   my $at_least_one_lived  = pexists(@pid_list, {any => 1});
   my $all_pids_lived      = pexists(@pid_list, {all => 1});

  
=head1 FUNCTIONS

=head2 pexists( @pids, [ $argsref ] )
Supported arguments are 'any' and 'all'. See description above.

=head2 supported()
Returns a true value if the /proc filesystem is mounted.

=head1 DESCRIPTION

A quick and simple module for checking whether a process exists or
not.


=head1 INTERFACE 

Only the pexists sub can be exported. supported() must be called as
Proc::Exists::supported().


=head1 DIAGNOSTICS

If Proc::Exists::supported() cannot find a mechanism for
finding processes, it will return a false value.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Currently requires a mounted /proc filesystem.

Please report any bugs or feature requests to
C<bug-proc-exists@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


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
