#
# このファイルのエンコーディングはUTF-8
#

use Test::More;
use strict;
#BEGIN { plan tests => 'no_plan' };
BEGIN { plan tests => 14 };
use JSON;
#use utf8;
#########################
my ($js,$obj,$str);

$obj = {test => qq|abc"def|};
$str = objToJson($obj);
is($str,q|{"test":"abc\"def"}|);

$obj = {qq|te"st| => qq|abc"def|};
$str = objToJson($obj);
is($str,q|{"te\"st":"abc\"def"}|);

$obj = {test => qq|abc/def|};
$str = objToJson($obj);
is($str,q|{"test":"abc\/def"}|);
$obj = jsonToObj($str);
is($obj->{test},q|abc\/def|);

$obj = {test => q|abc\def|};
$str = objToJson($obj);
is($str,q|{"test":"abc\\\\def"}|);

$obj = {test => "abc\bdef"};
$str = objToJson($obj);
is($str,q|{"test":"abc\bdef"}|);

$obj = {test => "abc\fdef"};
$str = objToJson($obj);
is($str,q|{"test":"abc\fdef"}|);

$obj = {test => "abc\ndef"};
$str = objToJson($obj);
is($str,q|{"test":"abc\ndef"}|);

$obj = {test => "abc\rdef"};
$str = objToJson($obj);
is($str,q|{"test":"abc\rdef"}|);

$obj = {test => "abc-def"};
$str = objToJson($obj);
is($str,q|{"test":"abc-def"}|);

$obj = {test => "abc(def"};
$str = objToJson($obj);
is($str,q|{"test":"abc(def"}|);

$obj = {test => "abc\\def"};
$str = objToJson($obj);
is($str,q|{"test":"abc\\\\def"}|);

$obj = {test => "あいうえお"};
$str = objToJson($obj);
is($str,q|{"test":"あいうえお"}|);

$obj = {"あいうえお" => "かきくけこ"};
$str = objToJson($obj);
is($str,q|{"あいうえお":"かきくけこ"}|);
