use Test::More;
use strict;
BEGIN { plan tests => 2 };
use JSON;

#########################

my $js  = qw|{"foo":"bar"}|;
my $obj = jsonToObj($js);

is($obj->{foo},'bar');

$js = objToJson($obj);

is($js,'{"foo":"bar"}');
