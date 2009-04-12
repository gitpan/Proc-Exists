#!perl -w

use strict;
use Test::More tests => 1;

my $required_ok = 1;
eval {
	require Proc::Exists;
}; if($@) {
	diag( "can't load Proc::Exists: $@" );
	$required_ok = 0;
}
ok($required_ok);

#if we were able to load, output some extra info

if($required_ok) {
	my $impl = $Proc::Exists::pureperl ? "pureperl" :
		"XS (via ".$Proc::Exists::_loader.")";
	diag( "Testing Proc::Exists $Proc::Exists::VERSION, $impl implementation" );
	diag( "EPERM: $Proc::Exists::Configuration::EPERM, ".
	      "ESRCH: $Proc::Exists::Configuration::ESRCH");
	#the rest of this is just to shut up the warnings pragma
	$impl = $Proc::Exists::pureperl.$Proc::Exists::Configuration::EPERM.
	        $Proc::Exists::Configuration::ESRCH; 
	$impl = $Proc::Exists::_loader; #seperate because it can be undef with PP
	$impl = $Proc::Exists::VERSION;  #for old versions (pre 5.6, i think)
}

