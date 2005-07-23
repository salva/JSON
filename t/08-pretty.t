#!/usr/bin/perl -w

use strict;
use Test::More;
BEGIN { plan tests => 19 };

use JSON;

my ($js,$obj,$json);

$obj = {foo => "bar"};
$js = objToJson($obj);
is($js,q|{"foo":"bar"}|);

$obj = [10, "hoge", {foo => "bar"}];
$js = objToJson($obj, {pretty => 1});
is($js,q|[
  10,
  "hoge",
  {
    "foo" : "bar"
  }
]|);

$obj = [10, "hoge", {foo => "bar"}];
$js = objToJson($obj, {pretty => 1, indent => 1});
is($js,q|[
 10,
 "hoge",
 {
  "foo" : "bar"
 }
]|, "indent => 1");

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = objToJson($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|);


$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = objToJson($obj, {pretty => 1});
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|);

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = objToJson($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|);

$json = new JSON;

$obj = {foo => "bar"};
$js = $json->objToJson($obj);
is($js,q|{"foo":"bar"}|, "OOP");

$obj = [10, "hoge", {foo => "bar"}];
$js = $json->objToJson($obj, {pretty => 1});
is($js,q|[
  10,
  "hoge",
  {
    "foo" : "bar"
  }
]|, "OOP");

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $json->objToJson($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP");


$json = new JSON (pretty => 1);

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = $json->objToJson($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP new JSON (pretty => 1)");

$js = $json->objToJson($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP (pretty => 1)");

$js = $json->objToJson($obj, {pretty => 0});
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP (pretty => 0)");

$json->pretty(1);
$js = $json->objToJson($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, "OOP (pretty => 1)");

$json->pretty(0);
$js = $json->objToJson($obj);
is($js,q|{"foo":[{"a":"b"},0,1,2]}|, "OOP (pretty => 0)");

$obj = {foo => "bar"};
$json->pretty(1);
$json->delimiter(0);
is($json->objToJson($obj), qq|{\n  "foo":"bar"\n}|, "delimiter 0");
$json->delimiter(1);
is($json->objToJson($obj), qq|{\n  "foo": "bar"\n}|, "delimiter 1");
$json->delimiter(2);
is($json->objToJson($obj), qq|{\n  "foo" : "bar"\n}|, "delimiter 2");

#

{ local $JSON::Pretty = 1;

$obj = { foo => [ {a=>"b"}, 0, 1, 2 ] };
$js = objToJson($obj);
is($js,q|{
  "foo" : [
    {
      "a" : "b"
    },
    0,
    1,
    2
  ]
}|, 'local $JSON::Pretty = 1');

  local $JSON::Indent = 1;
$js = objToJson($obj);
is($js,q|{
 "foo" : [
  {
   "a" : "b"
  },
  0,
  1,
  2
 ]
}|, 'local $JSON::Indent = 1');

}
