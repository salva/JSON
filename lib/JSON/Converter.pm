
package JSON::Converter;

use vars qw($AUTOCONVERT $VERSION);
use Carp;

$VERSION     = 0.991;

$AUTOCONVERT = 1;

sub new { bless {}, shift; }

sub objToJson {
	my $self = shift;
	my $obj  = shift;

	$self->{_stack_myself} = [];

	local $AUTOCONVERT = $JSON::AUTOCONVERT;

	if(ref($obj) eq 'HASH'){
		return $self->hashToJson($obj);
	}
	elsif(ref($obj) eq 'ARRAY'){
		return $self->arrayToJson($obj);
	}
	else{
		return;
	}
}

sub hashToJson {
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
			$res{$k} = $self->hashToJson($v);
		}
		elsif(ref($v) eq "ARRAY"){
			$res{$k} = $self->arrayToJson($v);
		}
		else{
			$res{$k} = $self->valueToJson($v);
		}
	}

	pop @{ $self->{_stack_myself} };

	return '{' . join(',',map { _stringfy($_) . ':' .$res{$_} } keys %res) . '}';
}


sub arrayToJson {
	my $self = shift;
	my $obj  = shift;
	my @res;

	if(grep { $_ == $obj } @{ $self->{_stack_myself} }){
		die "circle ref!";
	}

	push @{ $self->{_stack_myself} },$obj;

	for my $v (@$obj){
		if(ref($v) eq "HASH"){
			push @res,$self->hashToJson($v);
		}
		elsif(ref($v) eq "ARRAY"){
			push @res,$self->arrayToJson($v);
		}
		else{
			push @res,$self->valueToJson($v);
		}
	}

	pop @{ $self->{_stack_myself} };

	return '[' . join(',',@res) . ']';
}


sub valueToJson {
	my $self  = shift;
	my $value = shift;

	return 'null' if(!defined $value);

	if($AUTOCONVERT and !ref($value)){
		return $value  if($value =~ /^-?(?:0|[1-9][\d]*)(?:\.[\d]+)?$/);
		return 'true'  if($value =~ /^true$/i);
		return 'false' if($value =~ /^false$/i);
	}

	if(! ref($value) ){
		return _stringfy($value)
	}
	elsif(ref($value) eq 'CODE'){
		my $ret = $value->();
		return 'null' if(!defined $ret);
		return _stringfy($ret);
	}
	elsif( ! UNIVERSAL::isa($value, 'JSON::NotString') ){
		die "Invalid value";
	}

	return defined $value->{value} ? $value->{value} : 'null';
}


sub _stringfy {
	my $arg = shift;
	my $l   = length $arg;
	my $s   = '"';
	my $i = 0;

	while($i < $l){
		my $c = substr($arg,$i++,1);
		if($c ge ' '){
			$c =~ s{(["\\/])}{\\$1};
			$s .= $c;
		}
		elsif($c =~ tr/\n\r\t\f\b/nrtfb/){
			$s .= '\\' . $c;
		}
		else{
			$s .= '\\u00' . unpack('H2',$c);
		}
	}

	return $s . '"';
}



1;
__END__


=head1 METHODs

=over

=item parse

alias of C<objToJson>.

=item objToJson

convert a passed perl data structure into JSON object.
can't parse bleesed object.

=item hashToJson

convert a passed hash into JSON object.

=item arrayToJson

convert a passed array into JSON array.

=item valueToJson

convert a passed data into a string of JSON.

=back

=head1 COPYRIGHT

makamaka [at] donzoko.net

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.crockford.com/JSON/index.html>

=cut
