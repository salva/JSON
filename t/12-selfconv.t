#+++ JSON-1.01.modified/t/12-selfconvert.t	2005-12-19 11:42:36.000000000 +0100
#@@ -0,0 +1,109 @@

use Test::More;
use strict;
BEGIN { plan tests => 15 };
use JSON;

my ($obj, $obj2, $js);

## If selfconvert isn't enabled, it gets converted as usual 
$obj  = new MyTest;
$js = objToJson($obj);
ok(!defined $js, "Everything works as usual if not enabled");

eval { objToJson({a => $obj}) };
like $@, qr/Invalid value/, "skip invalid if you want smth...";

{
  local $JSON::SkipInvalid = 1;
  $js = objToJson({a => $obj});
  cmp_ok($js, 'eq', '{"a":null}', "Everything works as usual if not enabled");
}

## Now let's try with the SelfConvert option
{
    local $JSON::SelfConvert = 1;

    # the default 
    $obj  = new MyTest;
    $js = objToJson($obj);
    cmp_ok $js, 'eq', "default", "self converted !";

    my $hash = {b => "c", d => ["e", 1], f => { g => 'h' } };
    my $array = [ 'a', -0.12, {c => 'd'}, 0x0E, 100_000_000, 10E3];
    my $value = "value{},[]:";

    my @tests = ( 
        {
            mesg     => "_toJson call", 
            expected => '{"a":"b"}',
            meth     => sub { $_[1]->_toJson({ a => 'b'}) },
        },
        {
            mesg     => "call to hashToJson", 
            expected => '{"a":'.objToJson($hash).'}', 
            meth     => sub { '{"a":'. $_[1]->hashToJson($hash). '}' },
        },
        {
            mesg     => "call to arrayToJson", 
            expected => objToJson($array), 
            meth     => sub { $_[1]->arrayToJson($array) },
        },
        {
            mesg     => "call to valueToJson", 
            expected => objToJson({a => $value }), 
            meth     => sub { '{"a":'. $_[1]->valueToJson($value).'}' },
        },
    );

    for (@tests) {
        $obj->{json} = $_->{meth};
        cmp_ok objToJson($obj), 'eq', $_->{expected}, $_->{mesg};
    }

    # as a Hash value (no conflict with skipinvalid)
    $obj->{json} = sub { '"youhou"' };
    cmp_ok objToJson({a => $obj}), 'eq', '{"a":"youhou"}', "hash - skipinvalid not necessary"; 

    # as an Array member (no conflict with skipinvalid) 
    $obj->{json} = sub { '"youhou"' };
    cmp_ok objToJson(['a', $obj]), 'eq', '["a","youhou"]', "array - skipinvalid not necessary"; 
    # null / false / true 
    for (qw(null false true)) {
        $obj->{json} = sub { $_ };
        cmp_ok objToJson({a => $obj}), 'eq', "{\"a\":$_}", "obj to $_ value"; 
    }

    # circle ref 1
    $obj->{json} = sub { 
        my $self = shift; # $obj
        my $json = shift;
        $json->_hashToJson({ a => $self });
    };

    eval { $js = objToJson($obj); };
    like($@, qr/circle ref/, "don't ask an object to recursively jsonize itself");

    # circle ref 2
    $obj->{json} = sub { 
        my $self = shift; # $obj
        my $json = shift;
        my $struct1 = { b => 'c' };
        my $struct2 = { d => $struct1 };
        $struct1->{b} = $struct2;
        $json->_hashToJson({ a => $struct1 });
    };
    eval { $js = objToJson($obj); };
    like($@, qr/circle ref/, "usual circle ref is detected");
}

########################
package MyTest;

sub new { return bless { json => sub { 'default' } }, 'MyTest'; }

sub toJson {
    my $self = shift;
    return $self->{json}->($self, @_);
}

__END__
