#!perl

use strict; use warnings;

my @tests = (
	{ msg => "nonexistent process" },
	{ msg => "process owned by another user" },
	{ msg => "process owned by you", xtra => 'enter for $$' },
);

foreach my $test (@tests) {
	my $m = $test->{msg};
	print "Input the pid of a ".$test->{msg};
	print ' ('.$test->{xtra}.')' if($test->{xtra});
	print ': ';
	my $pid = <>;
	chomp($pid);
	$pid = $$ if($pid eq '' && $test->{xtra});
	my $ret = kill(0, $pid);
	$test->{err} = $!; 
	$test->{ret} = $ret; 
}

print "\n\n=== results ===\nOS: $^O\n"; 
foreach my $test (@tests) {
	my ($m, $ret, $err) = ($test->{msg}, $test->{ret}, $test->{err});
	print "$m test got ret: $ret, \$!: $err\n";
}

