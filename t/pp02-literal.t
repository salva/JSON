use Test::More;

BEGIN { plan tests => 26 };
use JSON::PP;


is(to_json([JSON::PP::true]),  q|[true]|);
is(to_json([JSON::PP::false]), q|[false]|);
is(to_json([JSON::PP::null]),  q|[null]|);

my $jsontext = q|[true,false,null]|;
my $obj      = from_json($jsontext, {literal_value => 1});

isa_ok($obj->[0], 'JSON::PP::Boolean');
isa_ok($obj->[1], 'JSON::PP::Boolean');
ok(!defined $obj->[2], 'null is undef');

ok($obj->[0] == 1);
ok($obj->[0] != 0);
ok($obj->[1] == 0);
ok($obj->[1] != 1);
# ok($obj->[2] != 1 and $obj->[2] != 0); # perl undef is treated as false.

ok($obj->[0] eq 'true', 'eq true');
ok($obj->[0] ne 'false', 'ne false');
ok($obj->[1] eq 'false', 'eq false');
ok($obj->[1] ne 'true', 'ne true');
#ok($obj->[2] eq 'null', 'eq null');
#ok($obj->[2] ne 'true', 'ne true');
#ok($obj->[2] ne 'false', 'ne false');

ok($obj->[0] eq $obj->[0]);
ok($obj->[0] ne $obj->[1]);
#ok($obj->[2] eq $obj->[2]);
#ok($obj->[2] ne $obj->[0]);
#ok($obj->[2] ne $obj->[1]);

ok(JSON::PP::true  eq 'true');
ok(JSON::PP::true  ne 'false');
ok(JSON::PP::true  ne 'null');
ok(JSON::PP::false eq 'false');
ok(JSON::PP::false ne 'true');
ok(JSON::PP::false ne 'null');
ok(!defined JSON::PP::null);
#ok(JSON::null  ne 'false');
#ok(JSON::null  ne 'true');

is(from_json('[true]' )->[0], JSON::PP::true);
is(from_json('[false]')->[0], JSON::PP::false);
is(from_json('[null]' )->[0],  JSON::PP::null);

