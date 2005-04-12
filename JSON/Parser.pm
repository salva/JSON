package JSON::Parser;

use strict;
use Parse::RecDescent;

use vars qw($VERSION);

$VERSION     = 0.5;

my $grammar = q {
	{
		my $comments = q{(\s*(//[^\n]*)\n\s*)|(?sx-im:\s*(/[*] .*? [*]/\s*)*)};
	}
	rule     : object                { $JSON::Parser::OBJ = $item[1] }
	         | array                 { $JSON::Parser::OBJ = $item[1] }
	         | <error>

	object   : <skip: "$comments"> '{' member(s? /,/) '}' { my $hash = { (map { %$_ } @{$item[3]}) }; }

	array    : <skip: "$comments"> '[' value(s? /,/) ']'  { $item[3] }

	member   : <skip: "$comments"> string ':' value      { {"$item[2]" => $item[4]} }

	value    : string { my $str = $item[1]; $str =~ s/\\\\(["\\\\])/$1/g; $str; }
	         | number
	         | object
	         | array
	         | true | false | null
	         | <error>

	string   : '"' /([^"\\\\]|\\\\["bfnrtu\/\\\\])*/ '"' { $item[2] }

	number   : /-?(0|[1-9][0-9]*)(.[0-9]+)?/
	                                    { bless {value => $item[1]}, 'JSON::NotString' }
	true     : 'true'                   { bless {value => 'true'  }, 'JSON::NotString' }
	false    : 'false'                  { bless {value => 'false' }, 'JSON::NotString' }
	null     : 'null'                   { bless {value => undef   }, 'JSON::NotString' }
};

sub new {
	my $class = shift;
	my $self  = {};

	$self->{parser}= new Parse::RecDescent ($grammar);

	bless $self,$class;
}

sub parse {
	my $self = shift;
	my $js   = shift;

	local $JSON::Parser::OBJ;

	$self->{parser} ||= new Parse::RecDescent ($grammar);

	$self->{parser}->rule($js);
}

sub jsonToObj {
	my $self = shift;
	my $js   = shift;

	local $JSON::Parser::OBJ;

	$self->{parser} ||= new Parse::RecDescent ($grammar) || die $!;

	$self->{parser}->rule($js);

	$JSON::Parser::OBJ;
}

package JSON::NotString;

use overload (
	'""'   => sub { $_[0]->{value} },
	'bool' => sub {
		  ! defined $_[0]->{value}  ? undef
		: $_[0]->{value} eq 'false' ? 0 : 1;
	},
);


1;

__END__

=head1 SEE ALSO

L<Parse::RecDescent>

L</http://www.crockford.com/JSON/index.html>

=head1 COPYRIGHT

makamaka [at] donzoko.net

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
