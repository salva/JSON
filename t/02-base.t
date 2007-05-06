use Test::More;
use strict;
BEGIN { plan tests => 60 };
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

ok($obj->[0] == 1);
ok($obj->[0] != 0);
ok($obj->[1] == 0);
ok($obj->[1] != 1);
ok($obj->[2] != 1 and $obj->[2] != 0);


{ local $JSON::UnMapping = 1;
$js  = q|[true,false,null]|;
$obj = jsonToObj($js);
is($obj->[0],1,'unmapping true');
is($obj->[1],0,'unmapping false');
ok(!defined $obj->[2],'unmapping null');
}

$js = objToJson([JSON::True, JSON::False, JSON::Null]);
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
#jsonToObj($js);
like($@, qr/Bad string/i, 'Bad string');

{ local $JSON::ExecCoderef = 1;

$obj = { foo => sub { "bar"; } };
$js = objToJson($obj);
is($js, '{"foo":"bar"}', "coderef bar");

$obj = { foo => sub { return } };
$js = objToJson($obj);
is($js, '{"foo":null}', "coderef undef");

$obj = { foo => sub { [1, 2, {foo => "bar"}]; } };
$js = objToJson($obj);
is($js, '{"foo":[1,2,{"foo":"bar"}]}', "coderef complex");

}

{ local $JSON::ExecCoderef = 0;
  local $JSON::SkipInvalid = 1;

$obj = { foo => sub { "bar"; } };
$js = objToJson($obj);
is($js, '{"foo":null}', "skipinvalid && coderef bar");

}

$obj = { foo => sub { "bar"; } };
eval q{ $js = objToJson($obj) };
like($@, qr/Invalid value/i, 'invalid value (coderef)');

$obj = { foo => *STDERR };
$js = objToJson($obj);
is($js, '{"foo":"*main::STDERR"}', "type blog");

$obj = { foo => \*STDERR };
eval q{ $js = objToJson($obj) };
like($@, qr/Invalid value/i, 'invalid value (ref of type blog)');

$obj = { foo => new JSON };
eval q{ $js = objToJson($obj) };
like($@, qr/Invalid value/i, 'invalid value (blessd object)');

$obj = { foo => \$js };
eval q{ $js = objToJson($obj) };
like($@, qr/Invalid value/i, 'invalid value (ref)');

