package Proc::Exists::Configuration;

use strict;
eval { require warnings; }; #it's ok if we can't load warnings

$Proc::Exists::Configuration::EPERM = 1;
$Proc::Exists::Configuration::ESRCH = 3;

1;
__END__

=head1 SYNOPSIS

Magic constants for Proc::Exists. Makefile.PL can clobber this file.


