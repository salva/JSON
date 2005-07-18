use Test::More;
use strict;
BEGIN { plan tests => 10 };
use JSON;

#########################
my ($js,$obj);


$js  = '{"foo":0x00}';
$obj = jsonToObj($js);
is($obj->{foo}, 0, "hex 00");

$js  = '{"foo":0x01}';
$obj = jsonToObj($js);
is($obj->{foo}, 1, "hex 01");

$js  = '{"foo":0x0a}';
$obj = jsonToObj($js);
is($obj->{foo}, 10, "hex 0a");

$js  = '{"foo":0x10}';
$obj = jsonToObj($js);
is($obj->{foo}, 16, "hex 10");

$js  = '{"foo":0xff}';
$obj = jsonToObj($js);
is($obj->{foo}, 255, "hex ff");

$js  = '{"foo":000}';
$obj = jsonToObj($js);
is($obj->{foo}, 0, "oct 0");

$js  = '{"foo":001}';
$obj = jsonToObj($js);
is($obj->{foo}, 1, "oct 1");

$js  = '{"foo":010}';
$obj = jsonToObj($js);
is($obj->{foo}, 8, "oct 10");

$js  = '{"foo":0x0g}';
eval q{ $obj = jsonToObj($js) };
like($@, qr/Bad object/i, 'Bad object (hex)');

$js  = '{"foo":008}';
eval q{ $obj = jsonToObj($js) };
like($@, qr/Bad object/i, 'Bad object (oct)');

