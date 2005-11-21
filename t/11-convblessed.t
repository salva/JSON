use Test::More;
use strict;
BEGIN { plan tests => 40 };
use JSON;

use CGI;
use IO::File;

my ($obj, $obj2, $js);

$obj  = new MyTest;
$js = objToJson($obj);
ok(!defined $js);

{
local $JSON::ConvBlessed = 1;
local $JSON::AUTOCONVERT = 1;

my ($obj, $obj2, $js);

$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = objToJson($obj);


like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":1.3/);

my $obj3 = jsonToObj($js);

is($obj3->{a}->[0], $obj->{a}->[0]);
is($obj3->{a}->[1], $obj->{a}->[1]);
is($obj3->{a}->[2], $obj->{a}->[2]);

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

$js = objToJson([$obj]);

like($js, qr/^\[{"[a-e]"/);
like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);

$js = objToJson({hoge => $obj});

like($js, qr/^{"hoge":{"[a-e]"/);
like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);

}



{
local $JSON::ConvBlessed = 1;
local $JSON::AUTOCONVERT = 1;


$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = objToJson($obj);

#print $js,"\n";

like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":1.3/);

my $obj3 = jsonToObj($js);

is($obj3->{a}->[0], $obj->{a}->[0]);
is($obj3->{a}->[1], $obj->{a}->[1]);
is($obj3->{a}->[2], $obj->{a}->[2]);

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

}


{
local $JSON::ConvBlessed = 1;
local $JSON::AUTOCONVERT = 0;


$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (JSON::Number(1),JSON::Number(2),JSON::Number(3));

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$js = objToJson($obj);

#print $js,"\n";

like($js, qr/"a":\[1,2,3\]/);
like($js, qr/"b":"{'a' => bless\( {}, 'MyTest' \)}"/);
like($js, qr/"d":1.3/);
like($js, qr/"e":"1.3"/);

my $obj3 = jsonToObj($js);

is($obj3->{a}->[0], "$obj->{a}->[0]");
is($obj3->{a}->[1], "$obj->{a}->[1]");
is($obj3->{a}->[2], "$obj->{a}->[2]");

is($obj3->{b}, $obj->{b});
is($obj3->{d}, "$obj->{d}");

}

my $json = new JSON;

$obj  = new MyTest;
$obj2 = new MyTest2;

@{$obj2} = (1,2,3);

$obj->{a} = $obj2;
$obj->{b} = q|{'a' => bless( {}, 'MyTest' )}|;
$obj->{c} = new CGI;
$obj->{d} = JSON::Number(1.3);
$obj->{e} = 1.3;

$json->convblessed(1);
$js = $json->objToJson($obj);
like($js, qr/"a":\[1,2,3\]/);

$json->convblessed(0);
$js = $json->objToJson($obj);
ok(!defined $js);

$json = JSON->new(convblessed => 0);
$js = $json->objToJson($obj);
ok(!defined $js);

$json = JSON->new(convblessed => 1);
$js = $json->objToJson($obj);
like($js, qr/"a":\[1,2,3\]/);

########################
package MyTest;

use overload (
	'""' => sub { 'test' },
);

sub new  { bless {}, shift; }

use overload (
	'""' => sub { 'test' },
);

package MyTest2;

sub new  { bless [], shift; }

__END__
