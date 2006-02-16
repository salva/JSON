use Test::More;
use strict;
BEGIN { plan tests => 8 };
use JSON;

#########################
my ($js,$obj);

use Data::Dumper;
#print Dumper($obj);

$js  = q|[-12.34]|;
$obj = jsonToObj($js);
is($obj->[0], -12.34, 'digit -12.34');
$js = objToJson($obj);
is($js,'[-12.34]', 'digit -12.34');

$js  = q|[-1.234e5]|;
$obj = jsonToObj($js);
is($obj->[0], -123400, 'digit -1.234e5');
$js = objToJson($obj);
is($js,'[-123400]', 'digit -1.234e5');

$js  = q|[1.23E-4]|;
$obj = jsonToObj($js);
is($obj->[0], 0.000123, 'digit 1.23E-4');
$js = objToJson($obj);
is($js,'[0.000123]', 'digit 1.23E-4');


$js  = q|[1.01e+30]|;
$obj = jsonToObj($js);
is($obj->[0], 1.01e+30, 'digit 1.01e+30');
$js = objToJson($obj);
like($js,qr/\[1.01[Ee]\+0?30\]/, 'digit 1.01e+30');

