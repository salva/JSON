use Test::More;
use strict;
BEGIN { plan tests => 3 };
use JSON;

my $obj = {a => 123};
my $obj1 = {};
my $obj2 = {};
my $obj3 = {};

$obj1->{a} = $obj1;

eval q{ objToJson($obj1) };
like($@, qr/circle ref/);

$obj1->{a} = $obj2;
$obj2->{b} = $obj3;
$obj3->{c} = $obj;

eval q{ objToJson($obj1) };
unlike($@, qr/circle ref/);
#is(objToJson($obj1), q|{"a":{"b":{"c":{"a":123}}}}|);

$obj1->{a} = $obj2;
$obj2->{b} = $obj3;
$obj3->{c} = $obj1;

eval q{ objToJson($obj1) };
like($@, qr/circle ref/);

