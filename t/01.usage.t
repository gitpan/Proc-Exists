use Test::More 'no_plan';

use Proc::Exists qw(pexists);

#make sure this process exists
ok(pexists($$));
#this process and init should give a count of 2
ok(2 == pexists(1, $$));
#check array context return
my @t = pexists(1, $$);
ok($t[0] == 1);
ok($t[1] == $$);
#check shortcutting with "any" arg
ok(1 == pexists(1, $$, {any => 1}));
#make sure we can get a negative response
ok(pexists(0..99999) < 100000);
#check shortcutting with "any" arg, again
ok(1 == pexists(0..99999, {any => 1}));
#make sure "all" arg works properly
ok(0 == pexists(0..99999, {all => 1}));
