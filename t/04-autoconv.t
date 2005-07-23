use Test::More;
use strict;
BEGIN { plan tests => 12 };
use JSON;

my $json = new JSON;
my ($js,$obj);

$obj = {"id" => JSON::Number("1.02")};
{ local $JSON::AUTOCONVERT = 0;
	$js = objToJson($obj);
	is($js,'{"id":1.02}');
	$js = $json->objToJson($obj);
	is($js,'{"id":1.02}');
}

	$js = $json->objToJson($obj);
	is($js,'{"id":1.02}');

$obj = {"id" => "1.02"};

{ local $JSON::AUTOCONVERT = 0;
	$js = objToJson($obj);
	is($js,'{"id":"1.02"}');

	$json->autoconv(0);
	$js = $json->objToJson($obj);
	is($js,'{"id":"1.02"}');
}

	$js = objToJson($obj);
	is($js,'{"id":1.02}');

	$js = $json->objToJson($obj);
	is($js,'{"id":"1.02"}');

	$json->autoconv(1);
	$js = $json->objToJson($obj);
	is($js,'{"id":1.02}');


$obj = {"id" => 1.02};
{ local $JSON::AUTOCONVERT = 0;
	$js = objToJson($obj);
	is($js,'{"id":"1.02"}');
}

	$js = objToJson($obj);
	is($js,'{"id":1.02}');

	$json = new JSON (autoconv => 0);
	$js = $json->objToJson($obj);
	is($js,'{"id":"1.02"}');

	$json = new JSON (autoconv => 1);
	$js = $json->objToJson($obj);
	is($js,'{"id":1.02}');

