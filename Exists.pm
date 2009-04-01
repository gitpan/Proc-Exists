package Proc::Exists;

use strict;
use Proc::Exists::Configuration;
use vars qw (@ISA @EXPORT_OK $VERSION); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@EXPORT_OK = qw(pexists);

$VERSION = '0.99';

eval {
	require XSLoader;
	XSLoader::load('Proc::Exists', $VERSION); 
}; if($@) {
	#NOTE: don't need to worry about i18n, {XS|Dyna}Loader complain in english.
	if($@ =~ /^Can.t\s+locate\s+loadable\s+object\s+for\s+module\s+Proc::Exists/) {
		#this usually means we want to use pureperl
	} elsif($@ =~ /Proc::Exists\s+object\s+version\s+\S+\s+does\s+not\s+match\s+bootstrap\s+parameter/ ) {
		die "ERROR: it looks like you have a previous Proc::Exists version's ".
           "object file(s) somewhere in \@INC! you will have to remove ".
           "these and reinstall Proc::Exists -- $@"; 
	} else {
		#there was a problem loading the XS, fall back to pureperl
		warn "WARNING: can't load XS, falling back to pureperl: $@\n"; 
	}
	#warn "using pure perl mode, expect degraded performance\n";
	my $EPERM = $Proc::Exists::Configuration::EPERM; 
	my $ESRCH = $Proc::Exists::Configuration::ESRCH; 
	my $pp_pexists = sub {
		my @pids = @_; 
		my %args = ref($pids[-1]) ? %{pop(@pids)} : ();

		die "can't specify both 'any' and 'all' arg" if($args{all} && $args{any}); 
		if(wantarray) {
			die "can't specify 'all' argument in list context" if($args{all}); 
			die "can't specify 'any' argument in list context" if($args{any}); 
		}

		my @results; 
		foreach my $pid (@pids) {
			#ASSUMPTION: no systems allow a negative int as a PID
			if($pid !~ /^\d+$/) {
				if($pid =~ /^-\d+$/) {
					die "got negative pid: '$pid'"; 
				} elsif($pid =~ /^-?\d+\./) {
					die "got non-integer pid: '$pid'"; 
				} else {
					die "got non-number pid: '$pid'"; 
				}
			}

			my $ret; 
			if (kill 0, $pid) {
				$ret = 1;
			} else {
				if($! == $EPERM) {
					$ret = 1;
				} elsif($! == $ESRCH) {
					$ret = 0;
				} elsif($^O eq "MSWin32") {
					die "can't do pure perl on MSWin32 - \$!: (".(0+$!)."): $!"; 
				} else {
					die "unknown numeric \$!: (".(0+$!)."): $!, pureperl, OS: $^O"; 
				}
			}

			if($ret) {
				return $pid if($args{any}); 
				push @results, $pid; 
			} elsif($args{all}) {
				return 0;
			}
		}
		#NOTE: as documented in the pod, any returns undef for false,
		#      because some systems use pid==0         
		return if($args{any}); 
		return wantarray ? @results : scalar @results; 
	};
	*pexists = \&$pp_pexists; 
	$Proc::Exists::pureperl = 1;

} else {

	my $xs_pexists = sub {
		my @pids = @_; 
		my %args = ref($pids[-1]) ? %{pop(@pids)} : ();

		if(wantarray) {
			die "can't specify 'all' argument in list context" if($args{all}); 
			die "can't specify 'any' argument in list context" if($args{any}); 
			return _list_pexists([@pids]); 
		} else {
			die "can't specify both 'any' and 'all' arg" if($args{all} && $args{any}); 
			return _scalar_pexists([@pids], $args{any} || 0, $args{all} || 0);
		}
	};
	*pexists = \&$xs_pexists; 
	$Proc::Exists::pureperl = 0;

}

# !wantarray        : return number of matches
# !wantarray && any : return pid of first match if any match, else undef
# !wantarray && all : return a true value if all match, else a false value
#  wantarray        : return list of matching pids
#  wantarray && any : undefined, makes no sense
#   ALTERNATELY: could return list of size one with first matching pid, 
#                else bare return
#  wantarray && all : undefined, makes no sense
#   ALTERNATELY: could return list of all pids on true, else bare return

1;
__END__

=head1 NAME

Proc::Exists - quickly and portably check for process existence


=head1 SYNOPSIS

   use Proc::Exists qw(pexists);

   my $dead_or_alive        = pexists($pid); 
   my @survivors            = pexists(@pid_list); 
   my $nsurvivors           = pexists(@pid_list); 
   my $all_pids_survived    = pexists(@pid_list, {all => 1});
   my $pid_of_one_survivor_or_undef_if_all_are_dead =
                              pexists(@pid_list, {any => 1});

  
=head1 FUNCTIONS

=head2 pexists( @pids, [ $args_hashref ] )

Supported arguments are 'any' and 'all', as shown above.

In list context, giving the 'any' or 'all' arguments will error out.

The 'any' argument returns the pid of the first process found, or undef 
if none are found. Note that on some systems, 0 is a valid and usually 
extant pid - see B<CAVEATS> for more information.

=head1 DESCRIPTION

A simple and fast module for checking whether a process exists or
not, regardless of whether it is a child of this process or has the
same owner. 

On POSIX systems, this is implemented by sending a 0 (test) signal to
the pid of the process to check and examining the result and errno.


=head1 DEPENDENCIES

 * any os with a POSIX layer or win32
 * Test::More if you want to run 'make test'

It's possible that if you don't have a C compiler, and you're
running an "obscure" UNIX-y OS (read: not linux, *BSD, solaris,
or Mac OS X), you might not pass make test. This is because we need
to compare the value of $! after a call to kill() with EPERM
and ESRCH. Not wanting to rely on Errno or POSIX, we determine EPERM 
and ESRCH at build (Makefile.PL) time, by using POSIX or Errno if
it exists -- but using the common values of EPERM==1 and ESRCH==3 if
we can't load POSIX. If you find yourself on such a system, your best 
bet is to look up EPERM and ESRCH (try grepping for them down 
/usr/include or wherever your headers are kept). If you get hits
back, you can edit Exists/Configuration.pm, add your values there, 
and re-run the build process. Whether you were successful or not, 
please send a descriptionof what you tried, as well as the output of 
perl -V and the results of perl misc/gather-info.pl to B<< 
<ski-cpan@allafrica.com> >> - making sure to include Proc::Exists in the 
subject line (or else I won't read it!) If you had no success, 
hopefully I'll be able to provide a patch for you, and a fix/workaround 
for the next release of Proc::Exists.

There is no pure perl implementation under Windows. The solution
is to use Strawberry Perl L<http://strawberryperl.com/>.

Any other OS without a POSIX emulation layer will probably be
completely non-functional (unless it implements C<kill()>).


=head1 CAVEATS

The 'any' argument returns the pid of the first process found, or undef 
if none are found. Note that on some systems (e.g. OSX), 0 is a valid 
pid (that almost always exists). Since the 'any' mode will return the 
first pid that matches, a return value of 0 can indicate that a pid was 
found. To avoid this problem, make sure you check whether 'any' mode 
found anything by checking for defined-ness, not whether the result 
evaluates to true or false in boolean context, like so:

	if(defined(pexists(@pid_list, {any => 1})));

B<< DO NOT >> use this idiom:

	if(pexists(@pid_list, {any => 1}));

Note also that this caveat does NOT apply for "plain" pexists() (ie 
without 'any' or 'all' arguments), because in scalar context a count is 
returned, so pexists(0) returns 1 when pid 0 exists, as expected. we 
only get a pid with 'any' or when we are in list context, and in the 
latter case, an array of length 1 containing a false value evaluates 
true in boolean context.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put 
Proc::Exists in the subject line if you want me to read your message.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, Brian Szymanski B<< <ski-cpan@allafrica.com> >>.
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
