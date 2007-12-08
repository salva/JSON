# copied over from JSON::XS and modified to use JSON

BEGIN { $| = 1; print "1..11\n"; }
BEGIN { $ENV{PERL_JSON_BACKEND} = 0; }

use JSON;

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, "\n";
}

my $def = 512;

my $js = JSON->new;

{
    local $^W = undef; # avoid for warning 'Deep recursion on subroutin'

ok (!eval { $js->decode (("[" x ($def + 1)) . ("]" x ($def + 1))) });
ok (ref $js->decode (("[" x $def) . ("]" x $def)));
ok (ref $js->decode (("{\"\":" x ($def - 1)) . "[]" . ("}" x ($def - 1))));
ok (!eval { $js->decode (("{\"\":" x $def) . "[]" . ("}" x $def)) });

}

ok (ref $js->max_depth (32)->decode (("[" x 32) . ("]" x 32)));

ok ($js->max_depth(1)->encode ([]));
ok (!eval { $js->encode ([[]]), 1 });

ok ($js->max_depth(2)->encode ([{}]));
ok (!eval { $js->encode ([[{}]]), 1 });

ok (eval { ref $js->max_size (7)->decode ("[      ]") });
eval { $js->max_size (7)->decode ("[       ]") }; ok ($@ =~ /max_size/);
