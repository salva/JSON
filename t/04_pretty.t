
use strict;
use Test::More;

BEGIN { plan tests => 3;}
BEGIN { $ENV{PERL_JSON_BACKEND} = 0; }

use JSON;


my $json = JSON->new->pretty;

my $obj = [
    [[]],
    [],
    [[[]],1,2,3],
];

is($json->encode($obj), q/[
   [
      []
   ],
   [],
   [
      [
         []
      ],
      1,
      2,
      3
   ]
]/
);


$obj = [
    { a => {} },
    { b => { c => {} } },
];

is($json->encode($obj), q/[
   {
      "a" : {}
   },
   {
      "b" : {
         "c" : {}
      }
   }
]/
);

$obj = [
    [],
    [],
    a => {
        ab => [[1,2,3]],
    },
    b => { c => {} },
];



is($json->encode($obj), q/[
   [],
   [],
   "a",
   {
      "ab" : [
         [
            1,
            2,
            3
         ]
      ]
   },
   "b",
   {
      "c" : {}
   }
]/
);

__END__
