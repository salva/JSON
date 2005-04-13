use Test::More;
use strict;
BEGIN { plan tests => 14 };
use JSON;

#########################
my ($js,$obj);

$js  = qw|{}|;
$obj = jsonToObj($js);
$obj = jsonToObj($js);
is($js,'{}');

$js  = qw|[]|;
$obj = jsonToObj($js);
$obj = jsonToObj($js);
is($js,'[]');

$js  = qw|{"foo":"bar"}|;
$obj = jsonToObj($js);
is($obj->{foo},'bar');
$js = objToJson($obj);
is($js,'{"foo":"bar"}');

$js  = qw|[1,2,3]|;
$obj = jsonToObj($js);
is(join(',',@$obj),'1,2,3');
$js = objToJson($obj);
is($js,'[1,2,3]');

$js = qw|{"foo":[1,2,3]}|;
$obj = jsonToObj($js);
is(join(',',@{$obj->{foo}}),'1,2,3');
$js = objToJson($obj);
is($js,'{"foo":[1,2,3]}');

$js = qw|{"foo":{"bar":"hoge"}}|;
$obj = jsonToObj($js);
is($obj->{foo}->{bar},'hoge');
$js = objToJson($obj);
is($js,qw|{"foo":{"bar":"hoge"}}|);

$js = qw|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|;
$obj = jsonToObj($js);
is(join(',',@{$obj->[0]->{foo}}),'1,2,3');
is(join(',',$obj->[1]),'-0.12');
is(join(',',$obj->[2]->{a}),'b');
$js = objToJson($obj);
is($js,qw|[{"foo":[1,2,3]},-0.12,{"a":"b"}]|);
