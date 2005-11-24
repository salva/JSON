package JSON::Converter;
##############################################################################

use Carp;

$JSON::Converter::VERSION = '1.05';

##############################################################################

sub new {
    my $class = shift;
    bless {indent => 2, pretty => 0, delimiter => 2, @_}, $class;
}


sub objToJson {
    my $self = shift;
    my $obj  = shift;
    my $opt  = shift;

    local(@{$self}{qw/autoconv execcoderef skipinvalid/});
    local(@{$self}{qw/pretty indent delimiter keysort convblessed/});

    $self->_initConvert($opt);

    if($self->{convblessed}){
        $obj = _blessedToNormal($obj);
    }

    #(not hash for speed)
    local @JSON::Converter::obj_addr; # check circular references 
    # for speed
    local $JSON::Converter::pretty  = $self->{pretty};
    local $JSON::Converter::keysort =  !$self->{keysort}                ? undef
                                      : ref($self->{keysort}) eq 'CODE' ? $self->{keysort}
                                      : $self->{keysort} =~ /\D+/       ? $self->{keysort}
                                      : sub { $a cmp $b };

    return $self->_toJson($obj);
}


*hashToJson  = \&objToJson;
*arrayToJson = \&objToJson;
*valueToJson = \&_valueToJson;


sub _toJson {
    my ($self, $obj) = @_;

    if(ref($obj) eq 'HASH'){
        return $self->_hashToJson($obj);
    }
    elsif(ref($obj) eq 'ARRAY'){
        return $self->_arrayToJson($obj);
    }
    else{
        return;
    }
}


sub _hashToJson {
    my $self = shift;
    my $obj  = shift;
    my ($k,$v);
    my %res;

    my ($pre,$post) = $self->_upIndent() if($JSON::Converter::pretty);

    if(grep { $_ == $obj } @JSON::Converter::obj_addr){
        die "circle ref!";
    }

    push @JSON::Converter::obj_addr,$obj;

    for my $k (keys %$obj){
        my $v = $obj->{$k};
        if(ref($v) eq "HASH"){
            $res{$k} = $self->_hashToJson($v);
        }
        elsif(ref($v) eq "ARRAY"){
            $res{$k} = $self->_arrayToJson($v);
        }
        else{
            $res{$k} = $self->_valueToJson($v);
        }
    }

    pop @JSON::Converter::obj_addr;

    if($JSON::Converter::pretty){
        $self->_downIndent();
        my $del = $self->{_delstr};
        return "{$pre"
         . join(",$pre", map { _stringfy($_) . $del .$res{$_} }
                (defined $JSON::Converter::keysort ? ( sort $JSON::Converter::keysort (keys %res)) : (keys %res) )
                ). "$post}";
    }
    else{
        return '{'. join(',',map { _stringfy($_) .':' .$res{$_} } 
                    (defined $JSON::Converter::keysort ?
                        ( sort $JSON::Converter::keysort (keys %res)) : (keys %res) )
                ) .'}';
    }

}


sub _arrayToJson {
    my $self = shift;
    my $obj  = shift;
    my @res;

    my ($pre,$post) = $self->_upIndent() if($JSON::Converter::pretty);

    if(grep { $_ == $obj } @JSON::Converter::obj_addr){
        die "circle ref!";
    }

    push @JSON::Converter::obj_addr,$obj;

    for my $v (@$obj){
        if(ref($v) eq "HASH"){
            push @res,$self->_hashToJson($v);
        }
        elsif(ref($v) eq "ARRAY"){
            push @res,$self->_arrayToJson($v);
        }
        else{
            push @res,$self->_valueToJson($v);
        }
    }

    pop @JSON::Converter::obj_addr;

    if($JSON::Converter::pretty){
        $self->_downIndent();
        return "[$pre" . join(",$pre" ,@res) . "$post]";
    }
    else{
        return '[' . join(',' ,@res) . ']';
    }
}


sub _valueToJson {
    my $self  = shift;
    my $value = shift;

    return 'null' if(!defined $value);

    if($self->{autoconv} and !ref($value)){
        return $value  if($value =~ /^-?(?:0|[1-9][\d]*)(?:\.[\d]*)?$/);
        return $value  if($value =~ /^0[xX](?:[0-9a-zA-Z])+$/);
        return 'true'  if($value =~ /^true$/i);
        return 'false' if($value =~ /^false$/i);
    }

    if(! ref($value) ){
        return _stringfy($value)
    }
    elsif($self->{execcoderef} and ref($value) eq 'CODE'){
        my $ret = $value->();
        return 'null' if(!defined $ret);
        return $self->_toJson($ret) if(ref($ret));
        return _stringfy($ret);
    }
    elsif( ! UNIVERSAL::isa($value, 'JSON::NotString') ){
        die "Invalid value" unless($self->{skipinvalid});
        return 'null';
    }

    return defined $value->{value} ? $value->{value} : 'null';
}


my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
);


sub _stringfy {
    my $arg = shift;
    $arg =~ s/([\\"\n\r\t\f\b])/$esc{$1}/eg;
    $arg =~ s/([\x00-\x07\x0b\x0e-\x1f])/'\\u00' . unpack('H2',$1)/eg;
    return '"' . $arg . '"';
}


##############################################################################

sub _initConvert {
    my $self = shift;
    my %opt  = %{ $_[0] } if(@_ > 0 and ref($_[0]) eq 'HASH');

    $self->{autoconv}    = $JSON::AUTOCONVERT if(!defined $self->{autoconv});
    $self->{execcoderef} = $JSON::ExecCoderef if(!defined $self->{execcoderef});
    $self->{skipinvalid} = $JSON::SkipInvalid if(!defined $self->{skipinvalid});

    $self->{pretty}      = $JSON::Pretty      if(!defined $self->{pretty});
    $self->{indent}      = $JSON::Indent      if(!defined $self->{indent});
    $self->{delimiter}   = $JSON::Delimiter   if(!defined $self->{delimiter});
    $self->{keysort}     = $JSON::KeySort     if(!defined $self->{keysort});
    $self->{convblessed} = $JSON::ConvBlessed if(!defined $self->{convblessed});

    for my $name (qw/autoconv execcoderef skipinvalid pretty indent delimiter keysort convblessed/){
        $self->{$name} = $opt{$name} if(defined $opt{$name});
    }

    $self->{indent_count} = 0;

    $self->{_delstr} = 
        $self->{delimiter} ? ($self->{delimiter} == 1 ? ': ' : ' : ') : ':';

    $self;
}


sub _upIndent {
    my $self  = shift;
    my $space = ' ' x $self->{indent};

    my ($pre,$post) = ('','');

    $post = "\n" . $space x $self->{indent_count};

    $self->{indent_count}++;

    $pre = "\n" . $space x $self->{indent_count};

    return ($pre,$post);
}


sub _downIndent { $_[0]->{indent_count}--; }


sub _isBlessedObj {
    return '' if(!ref($_[0]));
    ref($_[0]) eq 'HASH'  ? 'HASH' :
    ref($_[0]) eq 'ARRAY' ? 'ARRAY' :
    UNIVERSAL::isa($_[0],"JSON::NotString") ?  '' :
    (overload::StrVal($_[0]) =~ /=(\w+)/)[0];
}


sub _blessedToNormal { require overload;
    my ($obj) = @_;
    my $type  = _isBlessedObj($obj);

    local @JSON::Converter::_blessedToNormal::obj_addr;

    return $type eq 'HASH'  ? _blessedToNormalHash($obj)  : 
           $type eq 'ARRAY' ? _blessedToNormalArray($obj) : $obj;
}


sub _blessedToNormalHash {
    my ($obj) = @_;
    my %res;

    die "circle ref!" if(grep { overload::AddrRef($_) eq overload::AddrRef($obj) }
                          @JSON::Converter::_blessedToNormal::obj_addr);

    push @JSON::Converter::_blessedToNormal::obj_addr, $obj;

    for my $k (keys %$obj){
        my $v    = $obj->{$k};
        my $type = _isBlessedObj($v);

        if($type eq "HASH"){
            $res{$k} = _blessedToNormalHash($v);
        }
        elsif($type eq "ARRAY"){
            $res{$k} = _blessedToNormalArray($v);
        }
        else{
            $res{$k} = $v;
        }
    }

    pop @JSON::Converter::_blessedToNormal::obj_addr;

    return \%res;
}


sub _blessedToNormalArray {
    my ($obj) = @_;
    my @res;

    die "circle ref!" if(grep { overload::AddrRef($_) eq overload::AddrRef($obj) }
                          @JSON::Converter::_blessedToNormal::obj_addr);

    push @JSON::Converter::_blessedToNormal::obj_addr, $obj;

    for my $v (@$obj){
        my $type = _isBlessedObj($v);
        if($type eq "HASH"){
            push @res, _blessedToNormalHash($v);
        }
        elsif($type eq "ARRAY"){
            push @res, _blessedToNormalArray($v);
        }
        else{
            push @res, $v;
        }
    }

    pop @JSON::Converter::_blessedToNormal::obj_addr;

    return \@res;
}

##############################################################################
1;
__END__


=head1 METHODs

=over

=item objToJson

convert a passed perl data structure into JSON object.
can't parse bleesed object by default.

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

L<JSON>,
L<http://www.crockford.com/JSON/index.html>

=cut
