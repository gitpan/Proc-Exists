use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Proc::Exists',
	VERSION_FROM      => 'lib/Proc/Exists.pm', # finds $VERSION 
	PREREQ_PM => { 'Test::More' => 0, },
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/Proc/Exists.pm', # retrieve abstract from module
		 AUTHOR        => 'Brian Szymanski <ski-cpan@allafrica.com>') : ()),
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	##Un-comment this if you add C files to link with later:
	# OBJECT            => '$(O_FILES)', # link all the C files too

	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Proc-Exists-*' },

);
