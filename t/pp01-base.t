
use Test::More;
use strict;
BEGIN { plan tests => 20 };
use JSON::PP;

#########################
my ($js,$obj);

$js  = q|{}|;
$obj = jsonToObj($js);
$js  = objToJson($obj);
is($js,'{}');

$js  = q|[]|;
$obj = jsonToObj($js);
$js  = objToJson($obj);
is($js,'[]');

$js  = q|{"foo":"bar"}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');

$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":""}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{"foo":" "}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":" "}');


$js  = q|{"foo":"0"}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":"0"}',q|{"foo":"0"}|);

$js  = q|{"foo":"0 0"}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":"0 0"}','{"foo":"0 0"}');

$js  = q|[1,2,3]|;
$obj = jsonToObj($js);
is(join(',',@$obj),'1,2,3');
$js = objToJson($obj);
is($js,'[1,2,3]');


$js = q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

$js = objToJson([JSON::PP::true, JSON::PP::false, JSON::PP::null]);
is($js,'[true,false,null]', 'JSON::NotString [true,false,null]');

$obj = ["\x01"];
is($js = objToJson($obj),'["\\u0001"]');
$obj = jsonToObj($js);
is($obj->[0],"\x01");

$obj = ["\e"];
is($js = objToJson($obj),'["\\u001b"]');
$obj = jsonToObj($js);
is($obj->[0],"\e");

$js = '{"id":"}';
eval q{ jsonToObj($js) };
like($@, qr/unexpected end/i, 'Bad string');

__END__
