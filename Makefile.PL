#!perl
$|++;
use ExtUtils::MakeMaker;

use Config qw(%Config); #for $Config{cc}

# An existing makefile can confuse the CC test.
unlink('Makefile');

my $defines = '';
# win32 crud
if ($^O eq 'MSWin32') {
	if(defined($ENV{OS})) {
		if($ENV{OS} eq "Windows_NT") {
			# TODO: use multiples of 4 for pid
			$defines .= " -Dwin32_pids_mult4";
		} else {
			# win95/98/me, i presume...
			warn "wow, will i really run on $ENV{OS}?"; 
		}
	} else {
		warn "unsupported win32 OS - no \$ENV{OS} set...";
	}
}

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
	DEFINE            => $defines, # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	#MakeMaker LICENSE support: 6.30 - no, 6.30_0[1234] - yes, 6.31 - yes
	#also use NO_META here, which is kind of a hack but the machine I 
	#build on will always have it (>= 6.10_03)
	($ExtUtils::MakeMaker::VERSION > 6.30 ?
		(LICENSE => 'perl', NO_META => 1) :()),
	##Un-comment this if you add C files to link with later:
	# OBJECT          => '$(O_FILES)', # link all the C files too
	XS            => {},
	C             => [],

	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean             => { FILES => 'Proc-Exists-*' },
	realclean         => { FILES => '*~' },

);

#determine what C compiler to use, if any
my $CC; 
my $do_hacks;
my $err = use_pure_perl();
$Makefile{CC} = $CC; 
#don't try to link via a non-existent cc
if(($CC ne $Config{cc}) && ($Config{ld} eq $Config{cc})) {
	$Makefile{LD} = $CC; 
	#FIXME: there are other ways we could get here...
	$do_hacks = "solaris10_gcc";
}

if($err) {
	print "NO:\n   $err\n"; 
	print <<END;
I cannot detect a working C compiler. I will install the 
perl-only implementation. Expect degraded performance.
END
	delete $Makefile{CC}; 
	delete $Makefile{LD}; 
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
	print "Testing if you have a working C compiler and the needed header files...\n";

	return "cannot write compile.c" unless open(FH, ">compile.c");

	print FH <<'EOF';
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
int main() { return 0; }
EOF

	return "cannot close compile.c" unless close(FH); 

	#sometimes $Config{CC} is not the answer (e.g. solaris10 w/ gcc but
	#no cc package installed)...
	my @cc_alternatives = qw ( gcc cc egcs );
	my $ret;
	foreach my $cc ( $Config{cc}, @cc_alternatives )  {
		print "trying $cc... "; 
		my $cmd = "$cc -c compile.c -o compile$Config{obj_ext}"; 
		$ret = system($cmd); 
		if($ret==0) { $CC=$cc; last };
	}
   
	foreach my $file (glob('compile*')) {
		unlink($file); #who cares? #warn "Could not delete $file: $!\n"; 
	}

	if ($ret == 0) {
		return 0;
	} else {
		return "failed";
	}
}

WriteMakefile(%Makefile);

#on solaris10 with gcc we have to munge the Makefile a bit, ick...
if($do_hacks) {
	system("cp Makefile Makefile.unmangled");
	if ($do_hacks eq "solaris10_gcc") {
		#hacks for solaris10 with gcc
		for my $hack ( qw ( OPTIMIZE CCCDLFLAGS ) ) {
			system("grep -v '^$hack' Makefile >Makefile.$do_hacks"); 
			system("cp Makefile.$do_hacks Makefile");
		}
	}
}
