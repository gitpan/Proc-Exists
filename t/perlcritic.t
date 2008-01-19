#!perl

use Test::More;
eval "use Test::Perl::Critic (-severity => 3)";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

Test::Perl::Critic::all_critic_ok();
