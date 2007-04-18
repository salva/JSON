
use Test::More;
BEGIN { plan tests => 1 };

use strict;
use JSON;


my %columns;
tie %columns, 'TestTie';

%columns = (
    foo => "bar",
);

my $js = objToJson(\%columns);
#print $js;

is($js, q|{"foo":"hoge"}|);


package TestTie;

use Tie::Hash;
use base qw(Tie::StdHash);

sub STORE {
    my ($self, $key, $value) = @_;
    $value =~ s/bar/hoge/;
    $self->{$key} = $value;
}



__END__
