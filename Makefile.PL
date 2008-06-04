#!perl
$|++;
use ExtUtils::MakeMaker;
use Cwd;
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

### if we can use POSIX, find out what EPERM and ESRCH are.
### if they aren't 1 and 3 (which seems standard), then clobber
### Exists/Configuration.pm with the new values. this is done
### here to avoid a dependency on POSIX, since we almost never
### need it. yes, this is ugly.
BEGIN {
	$::using_POSIX = 0;
	eval {
		require POSIX;
	}; if(!$@) {
		import POSIX qw(:errno_h);
		$::using_POSIX = 1;
	}
};
if($::using_POSIX) {
	my $EPERM = eval('EPERM');
	my $ESRCH = eval('ESRCH');
	my $wd = getcwd;
	chdir "Exists";
	open(CONF, "<Configuration.pm");
	my @lines = map { chomp; $_  } <CONF>; 
	close(CONF);
	my @t = grep(/./, map { /^\s*\$ESRCH = (\d+)\s*;\s*$/; $1 } @lines); 
	die "Configuration.pm in a weird state, not the right number of ESRCH's\n... if you are confused, restore Exists/Configuration.pm from the distribution\n" if(@t != 1);
	my $OLD_ESRCH = $t[0]; 
	@t    = grep(/./, map { /^\s*\$EPERM = (\d+)\s*;\s*$/; $1 } @lines); 
	die "Configuration.pm in a weird state, not the right number of EPERM's\n... if you are confused, restore Exists/Configuration.pm from the distribution\n" if(@t != 1);
	my $OLD_EPERM = $t[0]; 
	if($EPERM != $OLD_EPERM or $ESRCH != $OLD_ESRCH) {
		warn "updating Configuration.pm EPERM: $OLD_EPERM => $EPERM, ESRCH: $OLD_ESRCH => $ESRCH on $^O\n"; 
		foreach my $ln (0..$#lines) {
			$lines[$ln] =~ s/^\s*\$EPERM = \d+\s*;\s*$/\$EPERM = $EPERM;/; 
			$lines[$ln] =~ s/^\s*\$ESRCH = \d+\s*;\s*$/\$ESRCH = $ESRCH;/; 
		}
		open(CONF, ">Configuration.pm");
		print CONF "$_\n" foreach @lines; 
		close(CONF);
	}
	chdir($wd); 
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %Makefile = (
	NAME              => 'Proc::Exists',
	VERSION_FROM      => 'Exists.pm', # finds $VERSION 
	PREREQ_PM         => {
	                       'Cwd'                 => 0,
	                       'Config'              => 0,
	                       'Exporter'            => 0,
	                       'ExtUtils::MakeMaker' => 0,
	                       'Test::More'          => 0, 
                        },
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
if($CC && ($^O eq "solaris") && ($CC ne $Config{cc}) && ($Config{ld} eq $Config{cc})) {
	$Makefile{LD} = $CC; 
	#FIXME: are there other ways we could get here?
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
