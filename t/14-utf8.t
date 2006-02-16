use Test::More;
use strict;
BEGIN { plan tests => 19 };
use JSON;


#########################
my ($js,$obj);


SKIP: {
  skip "can't use utf8.", 19, unless( JSON->USE_UTF8 );

  if($] == 5.008){
     require Encode;
     *utf8::is_utf8 = sub { Encode::is_utf8($_[0]); }
  }


$js  = q|{"foo":"ばぁ"}|;


# $JSON::UTF8 = 0;

$obj = jsonToObj($js);
ok(!utf8::is_utf8($obj->{foo}), 'no UTF8 option');

$obj = jsonToObj($js, {utf8 => 1});
ok(utf8::is_utf8($obj->{foo}), 'UTF8 option');

$js = objToJson($obj);
ok(utf8::is_utf8($js), 'with UTF8');

$js  = q|{"foo":"ばぁ"}|;
$obj = jsonToObj($js);
ok(!utf8::is_utf8($js), 'without UTF8');

{
 use utf8;
 $js  = q|{"foo":"ばぁ"}|;
 $obj = jsonToObj($js);
 ok(utf8::is_utf8($obj->{foo}), 'with UTF8');
}

$js  = q|{"foo":"ばぁ"}|;

my $json = new JSON;

$obj = $json->parse_json($js,);
ok(!utf8::is_utf8($obj->{foo}), 'no utf8 option');

$obj = $json->parse_json($js, {utf8 => 1});
ok(utf8::is_utf8($obj->{foo}), 'with utf8 option');

$js = $json->objToJson($obj);
ok(utf8::is_utf8($js), 'utf8 option');

$js = $json->objToJson($obj);
ok(utf8::is_utf8($js), 'with UTF8 flag');





$js  = q|{"foo":"ばぁ"}|; # no UTF8


{ local $JSON::UTF8  = 1;

$obj = jsonToObj($js);
ok(utf8::is_utf8($obj->{foo}), '$JSON::UTF8 = 1');

$js = objToJson($obj);
ok(utf8::is_utf8($js));

$js  = q|{"foo":"ばぁ"}|; # no UTF8

$obj = jsonToObj($js, {utf8 => 0});
ok(!utf8::is_utf8($obj->{foo}), '$JSON::UTF8 = 1 but option is 0');

$obj = jsonToObj($js);
ok(utf8::is_utf8($obj->{foo}));

$JSON::UTF8  = 0;

  SKIP: {

    skip "doesn't work under some version (less than 5.8.3)", 1, unless( $] >= 5.008003 );

    $js  = q|{"foo":"ばぁ"}|; # no UTF8
    $obj = jsonToObj($js);
    $js = objToJson($obj);
    ok(!utf8::is_utf8($js), 'no UTF8');
    # use Devel::Peek;
    # print Devel::Peek::Dump($js);
  }
}


{
    local $JSON::UTF8 = 0;

    $js = q|["\u3042\u3044"]|;
    $obj = jsonToObj($js);

    ok( !utf8::is_utf8($obj->[0]) );

    $obj = jsonToObj($js, {utf8 => 1});
    ok( utf8::is_utf8($obj->[0]) );


    $js = q|{"\u3042\u3044" : "\u3042\u3044"}|;
    $obj = jsonToObj($js);

    ok(! utf8::is_utf8($obj->{"あい"}) );

    $obj = jsonToObj($js, {utf8 => 1});

  { use utf8;
    ok( utf8::is_utf8($obj->{"あい"}) );
    is($obj->{"あい"}, "あい");
  }
}

} # END





__END__

