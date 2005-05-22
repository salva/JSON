use Test::More;
use strict;
#BEGIN { plan tests => 'no_plan' };
BEGIN { plan tests => 11 };
use JSON;

my ($str,$obj);

$str = '/* test */ []';
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = "// test\n []";
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = '/* test ';
$obj = eval q|jsonToObj($str)|;
like($@, qr/Unterminated comment/, 'unterminated comment');

$str = '[]/* test */';
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = "/* test */\n []";
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = "// \n []";
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = '{"ab": /* test */ "b"}';
$obj = jsonToObj($str);
is(objToJson($obj),'{"ab":"b"}');

$str = "[  ]";
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

$str = "{  }";
$obj = jsonToObj($str);
is(objToJson($obj),'{}');

$str = "// test \n [ /* test */ \n // \n 123 // abc\n ]";
$obj = jsonToObj($str);
is(objToJson($obj),'[123]');


$str = "// \n [  ]";
$obj = jsonToObj($str);
is(objToJson($obj),'[]');

