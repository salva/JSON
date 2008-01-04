
use strict;
use Test::More;
BEGIN { plan tests => 3 };

BEGIN { $ENV{PERL_JSON_BACKEND} = 0; }

use JSON;

my $json = new JSON;


$json->allow_nonref->allow_blessed;

my $obj = Test->new({ foo => Test2->new({}), array => Test->new([1,2,3]) });


is($json->encode($obj), 'null');

$json->as_nonblessed;

like($json->encode($obj), qr/"array":\[1,2,3\]/);
like($json->encode($obj), qr/"foo":{}/);


package Test;


sub new {
    bless $_[1], $_[0];
}


package Test2;

use overload (
    '""' => sub { 'hogehoge' },
);

sub new {
    bless $_[1], $_[0];
}
