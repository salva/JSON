use Test::More;
use strict;
BEGIN { plan tests => 47 };
use JSON;

#########################
my ($js,$obj);

{ local $JSON::BareKey  = 1;
  local $JSON::QuotApos = 1;

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

$js  = q|{foo:"bar"}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{ふぅ:"ばぁ"}|;
$obj = jsonToObj($js);
is($obj->{"ふぅ"},'ばぁ', 'utf8');

$js  = q|{漢字！:"ばぁ"}|;
$obj = jsonToObj($js);
is($obj->{"漢字！"},'ばぁ', 'utf8');


$js  = q|{foo:'bar'}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":'bar'}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":'b\'ar'}|;
$obj = jsonToObj($js);
is($obj->{foo},'b\'ar');
$js = objToJson($obj);
is($js,q|{"foo":"b'ar"}|);

$js  = q|{f'oo:"bar"}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Bad object/i);

$js  = q|{'foo':'bar'}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{"foo":""}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{foo:""}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{"foo":''}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{foo:''}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js = q|[{foo:[1,2,3]},-0.12,{a:"b"}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

$js = q|[{'foo':[1,2,3]},-0.12,{a:'b'}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

}


{ local $JSON::BareKey  = 1;
  local $JSON::QuotApos = 0;

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

$js  = q|{foo:"bar"}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = q|{foo:'bar'}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Syntax error/i);

$js  = q|{"foo":'bar'}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Syntax error/i);

$js  = q|{'foo':'bar'}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Bad String/i);

$js  = q|{"foo":""}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{foo:""}|;
$obj = jsonToObj($js);
$js = objToJson($obj);
is($js,'{"foo":""}');

$js  = q|{"foo":''}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Syntax error/i);

$js  = q|{foo:''}|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Syntax error/i);

$js = q|[{foo:[1,2,3]},-0.12,{a:"b"}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,q|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);

$js = q|[{foo:[1,2,3]},-0.12,{a:'b'}]|;
$obj = eval q| jsonToObj($js) |;
like($@, qr/Syntax error/i);

}

__END__

