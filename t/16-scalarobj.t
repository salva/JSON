
use Test::More;
BEGIN { plan tests => 1 };

use JSON;

my $str = 'http://www.example.com/';
my $obj = Test->new($str);



local $JSON::ConvBlessed = 1;

is(objToJson([$obj]), qq|["$str"]|);



package Test;

sub new {
    my ($class, $str) = @_;
    bless \$str, $class;
}

