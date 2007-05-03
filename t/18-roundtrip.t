use Test::More;

BEGIN { plan tests => 1 };
use JSON;

$JSON::AUTOCONVERT = 0;

my $jsontext = '[1, "1", 2.0, "2.0"]';

is(objToJson(jsonToObj($jsontext)), '[1,"1",2,"2.0"]');


