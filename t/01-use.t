# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More;
BEGIN { plan tests => 6 };
use JSON;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = new JSON::Parser;
my $conv   = new JSON::Converter;

isa_ok($parser,'JSON::Parser');
isa_ok($conv,'JSON::Converter');

ok($parser->parse('{}'));
ok($parser->parse('[]'));

ok(jsonToObj(qq|//   \n ["a","b", /*  */ {},123, null, true, false ]|));
