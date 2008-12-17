use Proc::Exists;
use Test::More tests => 1;

diag( "WARNING: ignore all warnings from this test ;-)\n" );
require Config;
my $archname = $Config::Config{archname}; 
my $osvers = $Config::Config{osvers}; 
diag( "osname: $^O, archname: $archname, osvers: $osvers\n" );
for my $pid (0..15) {
	my $out = kill 0, $pid;
	diag( "pid: $pid, out: $out, err: $! (".(0+$!).")\n" );
}
diag ( "using ".($Proc::Exists::pureperl ? "pureperl" : "XS")." implementation" );
#TODO: emit a warning about perl -le 'kill 0, 1; print $!'
#or perhaps just try it yoself?

ok(1);
