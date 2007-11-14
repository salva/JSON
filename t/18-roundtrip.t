use Test::More;

BEGIN { plan tests => 5 };
use JSON;

$JSON::AUTOCONVERT = 0;

my $jsontext = '[1, "1", 2.0, "2.0"]';

is(objToJson(jsonToObj($jsontext)), '[1,"1",2,"2.0"]');


# thanks to james.farrell rt#29139

$obj = [!1];
$js = objToJson($obj);
is( $js, '[""]' );
$obj = jsonToObj($js);
is($obj->[0],!1);

$obj = [!!2];
$js = objToJson($obj);
is( $js, '["1"]' );
$obj = jsonToObj($js);
is($obj->[0],!!2);
