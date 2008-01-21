use Test::More 'no_plan';

use Proc::Exists qw(pexists);

my @pids_to_strobe = (1..99999);

#for some of these tests we need >1 process, but we don't care what
#that other process is, so long as it is in memory for the duration
#of this test.
my $another_pid;
eval { $another_pid = getppid(); };
if($^O eq "MSWin32") {
	#note cygwin never gets here, it returns $^O eq "cygwin"
	#System Idle process is always at pid 0 on winXP, and hopefully
	#others. also "System": is at 8 in w2k, 4 in XP/server 2003
	$another_pid = 4; #System Idle Process on Windows XP
	#note on windows xp, pids are always =0 mod 4 (?!)
	@pids_to_strobe = map { $_ * 4 } (0..19999);
} elsif (!$another_pid) {
	$another_pid = 1; #gulp, hopefully there is something init-esque w/ pid 1?
}

#make sure this process exists
ok(pexists($$));
#this process and init should give a count of 2
ok(2 == pexists($another_pid, $$));
#check array context return
my @t = pexists($another_pid, $$);
#also check *order* of results
ok($t[0] == $another_pid);
ok($t[1] == $$);
#check shortcutting with "any" arg
ok(1 == pexists($another_pid, $$, {any => 1}));

#TODO: these tests are non-deterministic, unless our range a) covers
#a process we're guaranteed won't go away (e.g. parent on unix, idle on win)
#b) has at least one hole in it. for this to work, the range of pids to
#strobe must be long enough that we'll get both hits and misses, but
#small enough to run relatively quickly

ok(pexists(@pids_to_strobe) < scalar @pids_to_strobe);
#check shortcutting with "any" arg, again
ok(1 == pexists(@pids_to_strobe, {any => 1}));
#make sure "all" arg works properly
ok(0 == pexists(@pids_to_strobe, {all => 1}));
