use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Proc::Exists',
    AUTHOR              => 'Brian Szymanski <ski-cpan@allafrica.com>',
    VERSION_FROM        => 'lib/Proc/Exists.pm',
    ABSTRACT_FROM       => 'lib/Proc/Exists.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Proc-Exists-*' },
);
