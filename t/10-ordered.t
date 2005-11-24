use Test::More;
use strict;
BEGIN { plan tests => 8 };
use JSON;
#########################

my ($js,$obj);


{
local $JSON::KeySort = 'My::Package::sort_test';

$obj = {a=>1, b=>2, c=>3, d=>4, e=>5, f=>6, g=>7, h=>8, i=>9};
$js = objToJson($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);

$JSON::KeySort = 'My::Package::sort_test2';
$js = objToJson($obj);
is($js, q|{"i":9,"h":8,"g":7,"f":6,"e":5,"d":4,"c":3,"b":2,"a":1}|);

}

my $json = new JSON;

$json->keysort(\&My::Package::sort_test);
$js = $json->objToJson($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);

$json->keysort(\&My::Package::sort_test2);
$js = $json->objToJson($obj);
is($js, q|{"i":9,"h":8,"g":7,"f":6,"e":5,"d":4,"c":3,"b":2,"a":1}|);

$json = new JSON(keysort => \&My::Package::sort_test);
$json->pretty(1);
$js = $json->objToJson($obj);
is($js, q|{
  "a" : 1,
  "b" : 2,
  "c" : 3,
  "d" : 4,
  "e" : 5,
  "f" : 6,
  "g" : 7,
  "h" : 8,
  "i" : 9
}|);

$js = $json->objToJson($obj, {keysort => \&My::Package::sort_test2});
is($js, q|{
  "i" : 9,
  "h" : 8,
  "g" : 7,
  "f" : 6,
  "e" : 5,
  "d" : 4,
  "c" : 3,
  "b" : 2,
  "a" : 1
}|);



{
local $JSON::KeySort = 1;
$js = objToJson($obj);
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);

}

$js = objToJson($obj, {keysort => 1});
is($js, q|{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}|);


package My::Package;

sub sort_test {
    $JSON::Converter::a cmp $JSON::Converter::b;
}

sub sort_test2 {
    $JSON::Converter::b cmp $JSON::Converter::a;
}
