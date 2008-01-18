use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Proc::Exists',
    license             => 'perl',
    dist_author         => 'Brian Szymanski <ski-cpan@allafrica.com>',
    dist_version_from   => 'lib/Proc/Exists.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Proc-Exists-*' ],
);

$builder->create_build_script();
