
package JSON::Converter;

use vars qw($AUTOCONVERT $VERSION);
use Carp;

$VERSION     = 0.9;

$AUTOCONVERT = 1;

sub new { bless {}, shift; }

sub obj {
	my $self = shift;
	$self->{obj} = $_[0] if(@_ > 0);
	$self->{obj};
}


sub objToJson {
	my $self = shift;
	my $obj  = shift;

	$self->{_stack_myself} = [];

	local $AUTOCONVERT = $JSON::AUTOCONVERT;

	if(ref($obj) eq 'HASH'){
		return $self->hashToString($obj);
	}
	elsif(ref($obj) eq 'ARRAY'){
		return $self->arrayToString($obj);
	}
	else{
		return;
	}
}


sub hashToString {
	my $self = shift;
	my $obj  = shift;
	my ($k,$v);
	my %res;

	if(grep { $_ == $obj } @{ $self->{_stack_myself} }){
		die "circle ref!";
	}

	push @{ $self->{_stack_myself} },$obj;

	for my $k (keys %$obj){
		my $v = $obj->{$k};
		if(ref($v) eq "HASH"){
			$res{$k} = $self->hashToString($v);
		}
		elsif(ref($v) eq "ARRAY"){
			$res{$k} = $self->arrayToString($v);
		}
		else{
			$res{$k} = $self->valueToString($v);
		}
	}

	pop @{ $self->{_stack_myself} };

	return '{' . join(',',map { qq|"$_":| .$res{$_} } keys %res) . '}';
}


sub arrayToString {
	my $self = shift;
	my $obj  = shift;
	my @res;

	if(grep { $_ == $obj } @{ $self->{_stack_myself} }){
		die "circle ref!";
	}

	push @{ $self->{_stack_myself} },$obj;

	for my $v (@$obj){
		if(ref($v) eq "HASH"){
			push @res,$self->hashToString($v);
		}
		elsif(ref($v) eq "ARRAY"){
			push @res,$self->arrayToString($v);
		}
		else{
			push @res,$self->valueToString($v);
		}
	}

	pop @{ $self->{_stack_myself} };

	return '[' . join(',',@res) . ']';
}


sub valueToString {
	my $self  = shift;
	my $value = shift;

	return 'null'             if(!defined $value);

	if($AUTOCONVERT and !ref($value)){
		return $value  if($value =~ /^-?(0|[1-9][\d]*)(\.[\d])?$/);
		return 'true'  if($value =~ /^true$/i);
		return 'false' if($value =~ /^false$/i);
	}

	return  '"'. _quotemeta($value) . '"' unless(ref($value));

	if( $value->isa('JASON::NotSring') ){
		die "Invalid";
	}

	return defined $value->{value} ? $value->{value} : 'null';
}


sub _quotemeta {
	my $value = shift;

	return $value unless($value =~ /["\\]/);

	$value = quotemeta($value);
	$value =~ s{\\ }{ }g;
	$value =~ s{\\,}{,}g;
	$value =~ s{\\-}{-}g;
	$value =~ s{\\\.}{.}g;
	$value =~ s{\\\(}{(}g;
	$value =~ s{\\\)}{)}g;
	$value =~ s{"}{\"}g;

	return $value;
}

1;
__END__

=head1 SEE ALSO

L</http://www.crockford.com/JSON/index.html>

=head1 COPYRIGHT

makamaka [at] donzoko.net

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
