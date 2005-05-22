use Test::More;
use strict;
BEGIN { plan tests => 30 };
use JSON;

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

{ local $JSON::AUTOCONVERT = 0;
$js  = q|{"foo":"0"}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":"0"}',q|{"foo":"0"} - NO AUTOCONVERT|);
}

$js  = q|{"foo":"0 0"}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":"0 0"}','{"foo":"0 0"}');

$js  = q|[1,2,3]|;
$obj = jsonToObj($js);
is(join(',',@$obj),'1,2,3');
$js = objToJson($obj);
is($js,'[1,2,3]');

$js = q|{"foo":[1,2,3]}|;
$obj = jsonToObj($js);
is(join(',',@{$obj->{foo}}),'1,2,3');
$js = objToJson($obj);
is($js,'{"foo":[1,2,3]}');

$js = q|{"foo":{"bar":"hoge"}}|;
$obj = jsonToObj($js);
is($obj->{foo}->{bar},'hoge');
$js = objToJson($obj);
is($js,q|{"foo":{"bar":"hoge"}}|);

$js = q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);


$js  = q|[true,false,null]|;
$obj = jsonToObj($js);
isa_ok($obj->[0],'JSON::NotString');
isa_ok($obj->[1],'JSON::NotString');
isa_ok($obj->[2],'JSON::NotString');
ok($obj->[0],'true');
ok(!$obj->[1],'false');
ok(!$obj->[2],'null');
$js = objToJson($obj);
is($js,'[true,false,null]');

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
like($@, qr/Bad string/i, 'Bad string');

