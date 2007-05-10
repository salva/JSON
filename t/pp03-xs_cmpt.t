use Test::More;
use strict;
BEGIN { plan tests => 5 };
use JSON::PP;

# The code is from JSON::XS and modified for PP.

my $pp = JSON::PP->new->latin1->allow_nonref;

eval { $pp->decode ("[] ") };
ok(!$@);
eval { $pp->decode ("[] x") };
ok($@);

eval { $pp->decode ("[] /* This is valid */ ") };
ok(!$@);

ok(2 == ($pp->decode_prefix ("[][]"))[1]);
ok(3 == ($pp->decode_prefix ("[1] t"))[1]);

__END__


