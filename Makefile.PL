#!perl
$|++;
use 5.006;
use ExtUtils::MakeMaker;

use Config qw(%Config); #for $Config{cc}

# An existing makefile can confuse the CC test.
unlink('Makefile');

## do something better than this...
#if ($^O eq 'MSWin32') {
#	die "win32 not supported";
#}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %Makefile = (
	NAME              => 'Proc::Exists',
	VERSION_FROM      => 'Exists.pm', # finds $VERSION 
	PREREQ_PM         => { 'Test::More' => 0, },
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'Exists.pm', # retrieve abstract from module
		 AUTHOR        => 'Brian Szymanski <ski-cpan@allafrica.com>') : ()),
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	LICENSE           => 'gpl',
	##Un-comment this if you add C files to link with later:
	# OBJECT          => '$(O_FILES)', # link all the C files too
	XS            => {},
	C             => [],

	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean             => { FILES => 'Proc-Exists-*' },
	realclean         => { FILES => '*~' },

);

if(my $err = use_pure_perl()) {
	print "NO:\n   $err\n"; 
	print <<END;
I cannot detect a working C compiler. I will install the 
perl-only implementation. Expect degraded performance.
END
} else {
	print "YES\n";
	delete $Makefile{XS}; 
	delete $Makefile{C}; 
}

sub use_pure_perl {
	#
	# The perl/C checking voodoo is stolen from Olaf Kolkman's 
	# Net-DNS via Graham Barr's Scalar-List-Utils distribution.
	#
	print "Testing if you have a working C compiler and the needed header files... ";

	my $fh; 
	return "cannot write compile.c" unless open($fh, ">compile.c");

	print $fh <<'EOF';
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
int main() { return 0; }
EOF

	return "cannot close compile.c" unless close($fh); 

	my $cmd = "$Config{'cc'}  -c compile.c -o compile$Config{obj_ext}"; 
	my $ret = system($cmd);
   
	foreach my $file (glob('compile*')) {
		unlink($file); #who cares? #warn "Could not delete $file: $!\n"; 
	}

	if ($ret == 0) {
		return 0;
	} else {
		return "'$cmd' failed";
	}
}

WriteMakefile(%Makefile);
