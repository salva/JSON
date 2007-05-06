use Test::More;

BEGIN { plan tests => 35 };
use JSON::PP;


is(to_json([JSON::true]),  q|[true]|);
is(to_json([JSON::false]), q|[false]|);
is(to_json([JSON::null]),  q|[null]|);

my $jsontext = q|[true,false,null]|;
my $obj      = from_json($jsontext, {literal_value => 1});

isa_ok($obj->[0],  'JSON::Literal::true');
isa_ok($obj->[1], 'JSON::Literal::false');
isa_ok($obj->[2],  'JSON::Literal::null');

ok($obj->[0] == 1);
ok($obj->[0] != 0);
ok($obj->[1] == 0);
ok($obj->[1] != 1);
ok($obj->[2] != 1 and $obj->[2] != 0);

ok($obj->[0] eq 'true', 'eq true');
ok($obj->[0] ne 'false', 'ne false');
ok($obj->[1] eq 'false', 'eq false');
ok($obj->[1] ne 'true', 'ne true');
ok($obj->[2] eq 'null', 'eq null');
ok($obj->[2] ne 'true', 'ne true');
ok($obj->[2] ne 'false', 'ne false');

ok($obj->[0] eq $obj->[0]);
ok($obj->[0] ne $obj->[1]);
ok($obj->[2] eq $obj->[2]);
ok($obj->[2] ne $obj->[0]);
ok($obj->[2] ne $obj->[1]);

ok(JSON::true  eq 'true');
ok(JSON::true  ne 'false');
ok(JSON::true  ne 'null');
ok(JSON::false eq 'false');
ok(JSON::false ne 'true');
ok(JSON::false ne 'null');
ok(JSON::null  eq 'null');
ok(JSON::null  ne 'false');
ok(JSON::null  ne 'true');

is(from_json('[true]', {literal_value => 1})->[0],  JSON::true);
is(from_json('[false]', {literal_value => 1})->[0], JSON::false);
is(from_json('[null]', {literal_value => 1})->[0],  JSON::null);

