use Test::More;
use strict;
BEGIN { plan tests => 6 };
use JSON;

#########################
my ($js,$obj);

local $JSON::SingleQuote = 1;

$obj = { foo => "bar" };
$js = objToJson($obj);

is($js, q|{'foo':'bar'}|);

$JSON::SingleQuote = 0;
$js = objToJson($obj);
is($js, q|{"foo":"bar"}|);

$js = objToJson($obj, {singlequote => 1});
is($js, q|{'foo':'bar'}|);

my $json = new JSON (singlequote => 1);

is($json->to_json($obj), q|{'foo':'bar'}|);

$json->singlequote(1);
is($json->to_json($obj), q|{'foo':'bar'}|);

$json->singlequote(0);
is($json->to_json($obj), q|{"foo":"bar"}|);
