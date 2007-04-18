package JSON::PP;

# JSON-2.0

use 5.008;
use strict;
use base qw(Exporter);

use Carp ();
use B ();
use Encode ();
#use Devel::Peek;

$JSON::PP::VERSION = '0.01';


@JSON::PP::EXPORT = qw(from_json to_json jsonToObj objToJson);

*jsonToObj = *from_json;
*objToJson = *to_json;

sub to_json {
    my ($obj, $opt) = @_;
    if ($opt) {
        my $json = JSON::PP->new->utf8;
        for my $allow (qw/utf8 pretty allow_tied allow_nonref self_encode/) {
            $json->$allow($opt->{$allow}) if (exists $opt->{$allow});
        }
        return $json->encode($obj);
    }
    else {
        return __PACKAGE__->new->utf8->encode($obj);
    }
}


sub from_json {
    __PACKAGE__->new->utf8->decode(shift);
}


sub new {
    my $class = shift;
    my $self  = {};

    $self->{decoder} = new JSON::Decoder;
    $self->{encoder} = new JSON::Encoder;

    $self->{deny_nonref} = 1;
    $self->{max_depth}   = 512;

    bless $self, $class;
}


sub encode {
    my $self = shift;
    my $obj  = shift;
    my $str;

    #$self->{indent} = $self->{indent} ? 3 : 0; # JSON::XS
    $self->{indent} = $self->{indent} ? $self->{indent} : 0; # no JSON::XS compati

    for my $name (qw/ascii utf8 allow_nonref pretty indent space_before space_after
                    canonical max_depth allow_tied self_encode
    /) {
        $self->{encoder}->{$name} = $self->{$name};
    }

    $str = $self->{encoder}->to_json($obj);

    if ($self->{utf8}) {
        utf8::encode($str);
    }

    return $str;
}


sub decode {
    my $self = shift;
    my $json = shift;
 
    my $deny_nonref = $self->{deny_nonref};

    if ($self->{allow_nonref}) { $deny_nonref = 0; }

    local $JSON::Parser::deny_nonref = 1 if ($deny_nonref);

    my $obj = $self->{decoder}
                ->parse($json, {utf8 => $self->{utf8}, unmap => 1, max_depth => $self->{max_depth}});

    return $obj;
}


# accessor

sub property {
    my ($self, $name, $value) = @_;

    if (@_ == 1) {
        Carp::croak('property requires 1 or 2 arguments.');
    }
    elsif (@_ == 2) {
        $self->{$name};
    }
    else {
        $self->$name($value);
    }
}


# pretty printing

sub pretty {
    my ($self, $v) = @_;
    $self->{pretty} = defined $v ? $v : 1;

    if ($v) { # JSON::XS compati
        $self->indent(3);
        $self->space_before(1);
        $self->space_after(1);
    }
    else {
        $self->indent(0);
        $self->space_before(0);
        $self->space_after(0);
    }

    $self;
}

# method shrink is a dummy.

BEGIN {
    for my $name (qw/utf8 allow_nonref ascii indent space_before space_after canonical  max_depth
                    shrink deny_blessed_object UTF8_off allow_tied self_encode
    /)
    {
        eval qq|
            sub $name {
                \$_[0]->{$name} = defined \$_[1] ? \$_[1] : 1;
                \$_[0];
            }
        |;
    }

}


# 
# I'll unify Encoder & Decoder to JSON.pm.
#

###
### Perl => JSON
###

package JSON::Encoder;

use vars qw($VERSION);
use strict;
use overload;

$VERSION  = '0.01';

BEGIN {
    eval 'require Scalar::Util';
    unless($@){
        *JSON::Encoder::blessed = \&Scalar::Util::blessed;
    }
    else{ # This code is from Sclar::Util.
        # warn $@;
        eval 'sub UNIVERSAL::a_sub_not_likely_to_be_here { ref($_[0]) }';
        *JSON::Encoder::blessed = sub {
            local($@, $SIG{__DIE__}, $SIG{__WARN__});
            ref($_[0]) ? eval { $_[0]->a_sub_not_likely_to_be_here } : undef;
        };
    }
}


sub new {
    my $self = bless {}, shift;

    $self->{fallback} = sub { error('Invalid value.') };

    $self;
}

{

my $depth;
my $max_depth;
my $keysort;
my $indent;
my $indent_count;
my $ascii;
my $utf8;
my $self_encode;

sub to_json {
    my $self = shift;
    my $obj  = shift;

    $indent_count = 0;
    $indent       = $self->{indent};
    $depth        = 0;
    $max_depth    = $self->{max_depth} || 512;
    $ascii        = $self->{ascii};
    $utf8         = $self->{utf8};
    $self_encode  = $self->{self_encode};

    $keysort = !$self->{canonical} ? undef
                                   : ref($self->{canonical}) eq 'CODE' ? $self->{canonical}
                                   : $self->{canonical} =~ /\D+/       ? $self->{canonical}
                                   : sub { $a cmp $b };

    my $str  = $self->toJson($obj);

    if (!defined $str and $self->{allow_nonref}){
        $str = $self->valueToJson($obj);
    }

    error("non ref") unless(defined $str);

    return $str;
}


sub toJson {
    my ($self, $obj) = @_;
    my $type = ref($obj);

    if($type eq 'HASH'){
        return $self->hashToJson($obj);
    }
    elsif($type eq 'ARRAY'){
        return $self->arrayToJson($obj);
    }
    elsif ($type) { # blessed object?
        if (blessed($obj)) {
            if ($self->{self_encode} && $obj->can('toJson')) {
                return $self->selfToJson($obj);
            }
            elsif (!$obj->isa('JSON::NotString')) { # JSON::NotString => valueToJson
                ($type) = B::svref_2object($obj) =~ /(.+)=/;
                return   $type eq 'B::AV' ? $self->arrayToJson($obj)
                       : $type eq 'B::HV' ? $self->hashToJson($obj)
                       : undef;
            }
        }
        else {
            return;
        }
    }
    else{
        return;
    }
}


sub hashToJson {
    my ($self, $obj) = @_;
    my ($k,$v);
    my %res;

    error("data structure too deep (hit recursion limit)")
                                     if (++$depth > $max_depth);

    $self->_tie_object($obj, \%res) if ($self->{allow_tied});

    my ($pre, $post) = $indent ? $self->_upIndent() : ('', '');
    my $del = ($self->{space_before} ? ' ' : '') . ':' . ($self->{space_after} ? ' ' : '');

    for my $k (keys %$obj) {
        my $v = $obj->{$k};
        $res{$k} = $self->toJson($v) || $self->valueToJson($v);
    }

    $self->_downIndent() if ($indent);

    return '{' . $pre . join(",$pre", map { _stringfy($self, $_) . $del .$res{$_} } _sort($self, \%res)) . $post . '}';
}


sub arrayToJson {
    my ($self, $obj) = @_;
    my @res;

    error("data structure too deep (hit recursion limit)")
                                     if (++$depth > $max_depth);

    $self->_tie_object($obj, \@res) if ($self->{allow_tied});

    my ($pre, $post) = $indent ? $self->_upIndent() : ('', '');

    for my $v (@$obj){
        push @res, $self->toJson($v) || $self->valueToJson($v);
    }

    $self->_downIndent() if ($indent);

    return '[' . $pre . join(",$pre" ,@res) . $post . ']';
}


sub valueToJson {
    my ($self, $value) = @_;

    return 'null' if(!defined $value);

    my $b_obj = B::svref_2object(\$value);  # for round trip problem
    my $IOK   = $b_obj->FLAGS & 0x00010000; # IV
    my $NOK   = $b_obj->FLAGS & 0x00020000; # NV
    my $POK   = $b_obj->FLAGS & 0x00040000; # PV

    return $value if ($IOK or $NOK); # as is

    my $type = ref($value);

    if(!$type){
        return _stringfy($self, $value);
    }
    elsif( blessed($value) and  $value->isa('JSON::NotString') ){
        return $value->{str};
    }
    elsif ($type) {
        if ((overload::StrVal($value) =~ /=(\w+)/)[0]) {
            return $self->valueToJson("$value");
        }
        error("JSON can only non reference.") if ($type eq 'CODE');
        error("cannot encode reference.");
    }
    else {
        return $self->{fallback}->($value)
             if ($self->{fallback} and ref($self->{fallback}) eq 'CODE');
        #die "Invalid value" unless($self->{skipinvalid});
        return 'null';
    }

}


my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
#    "/"  => '\\/', # TODO
);


sub _stringfy {
    my ($self, $arg) = @_;
    my $is_utf8;

    if (utf8::is_utf8($arg)) {
        $is_utf8 = 1;
    }

    $arg =~ s/([\\"\n\r\t\f\b])/$esc{$1}/eg;

    unless ($utf8) {
        $arg =~ s/([\x00-\x07\x0b\x0e-\x1f])/'\\u00' . unpack('H2',$1)/eg;
    }

    if ($ascii) {
        $arg = join('',
            map {
                chr($_) =~ /[\x00-\x07\x0b\x0e-\x1f]/ ?
                    sprintf('\u%04x', $_) :
                $_ <= 127 ?
                    chr($_) :
                $_ <= 255 ?
                    sprintf('\u%04x', $_) :
                $_ <= 65535 ?
                    sprintf('\u%04x', $_) :
                    join("", map { '\u' . $_ } unpack("H4H4", Encode::encode('UTF-16BE', pack("U", $_))));
            } unpack('U*', $arg)
        );
    }

    if ($utf8 and !$self->{UTF8_off}) {
        utf8::decode($arg);
    }

    return '"' . $arg . '"';
}


#sub _to_UTF16 {
#    return sprintf("\\u%s\\u%s", unpack("H4H4", Encode::encode('UTF-16BE', pack("U", $_[0]))));
#    return join("", map { '\u' . $_ } unpack("H4H4", Encode::encode('UTF-16BE', pack("U", $_[0]))));
#    my $c = $_[0];
#    Encode::from_to($c, 'UTF-16BE', 'utf8');
#    join( "", map { '\u' . $_ } unpack('H4H4', $c) );
#}


sub selfToJson {
    my ($self, $obj) = @_;
    return $obj->toJson($self);
}


sub error {
    local $Carp::CarpLevel = 1;
    my $error  = shift;
    Carp::croak "$error";
}



sub _sort {
    my ($self, $res) = @_;
    defined $keysort ? (sort $keysort (keys %$res)) : keys %$res;
}


sub _tie_object {
    my ($self, $obj, $res) = @_;
    my $class;
    # by ddascalescu+perl [at] gmail.com
    if (ref($obj) eq 'ARRAY' and $class = tied @$obj) {
        $class =~ s/=.*//;
        tie @$res, $class;
    }
    elsif (ref($obj) eq 'HASH' and $class = tied %$obj) {
        $class =~ s/=.*//;
        tie %$res, $class;
    }
}



sub _upIndent {
    my $self  = shift;
    my $space = ' ' x $indent;

    my ($pre,$post) = ('','');

    $post = "\n" . $space x $indent_count;

    $indent_count++;

    $pre = "\n" . $space x $self->{indent_count};
    $pre = "\n" . $space x $indent_count;

    return ($pre,$post);
}


sub _downIndent { $_[0]->{indent_count}--; }


}

#
# JSON => Perl
#


package JSON::Decoder;

use vars qw($VERSION);
use strict;


$VERSION  = '0.01';

my %escapes = ( #  by Jeremy Muhlich <jmuhlich [at] bitflood.org>
  b    => "\x8",
  t    => "\x9",
  n    => "\xA",
  f    => "\xC",
  r    => "\xD",
#  '/'  => '/',
  '\\' => '\\',
);


sub new {
    my $class = shift;
    bless { @_ }, $class;
}


*jsonToObj = \&parse;


{ # PARSE 

    my $text;
    my $at;
    my $ch;
    my $len;

    my $unmap; # unmmaping
    my $bare;  # bareKey
    my $apos;  # loosely quoting
    my $utf8;  # 
    my $UTF8_off;  #
    my $max_depth; #

    my $is_utf8;
    my $depth;

    sub _init {
        my $opt  = $_[1] || {};
        $utf8  = $opt->{utf8};
        $unmap = $opt->{unmap};
        $max_depth = $opt->{max_depth};
    }

    sub parse {
        my $self = shift;
        $text = shift;
        $at   = 0;
        $ch   = '';

        $depth = 0;

        if ( utf8::is_utf8($text) ) {
            $is_utf8 = 1;
        }

        $len  = length $text;
        $self->_init(@_);

        if ($JSON::Parser::deny_nonref) {
            white();
            unless ($ch eq '{' or $ch eq '[') {
                error('JSON text must be an object or array'
                       . ' (but found number, string, true, false or null, use allow_nonref to allow this)', 1);
            }
        }

        value();
    }


    sub next_chr {
        return $ch = undef if($at >= $len);
        $ch = substr($text, $at++, 1);
    }


    sub value {
        white();
        return          if(!defined $ch);
        return object() if($ch eq '{');
        return array()  if($ch eq '[');
        return string() if($ch eq '"' or ($apos and $ch eq "'"));
        return number() if($ch eq '-');
        return $ch =~ /\d/ ? number() : word();
    }


    sub string {
        my ($i,$s,$t,$u);
        $s = '';
        my @utf16;

        if($ch eq '"' or ($apos and $ch eq "'")){
            my $boundChar = $ch;

            OUTER: while( defined(next_chr()) ){

                if($ch eq '"' or ($apos and $ch eq $boundChar)){
                    next_chr();

                    if (@utf16) {
                        error("missing low surrogate character in surrogate pair");
                    }

#                    if ($utf8 or $is_utf8) {
#                    if ($utf8 and $is_utf8) {
                    if ($utf8 and !$UTF8_off) {
                        utf8::decode($s);
                    }

                    return $s;
                }
                elsif($ch eq '\\'){
                    next_chr();
                    if(exists $escapes{$ch}){
                        $s .= $escapes{$ch};
                    }
                    elsif($ch eq 'u'){
                        my $u = ''; # UNICODE

                        for(1..4){
                            $ch = next_chr();
                            last OUTER if($ch !~ /[0-9a-fA-F]/);
                            $u .= $ch;
                        }

                        # U+10000 - U+10FFFF
                        if ($u =~ /^[dD][89abAB]/) { # UTF-16 high surrogate?
                            push @utf16, $u;
                        }
                        # U+DC00 - U+DFFF
                        elsif ($u =~ /^[dD][cdefCDEF]/) { # UTF-16 low surrogate?
                            unless (scalar(@utf16)) {
                                error("missing high surrogate character in surrogate pair");
                            }
                            push @utf16, $u;
                            my $str = pack('H4H4', @utf16);
                            $s .= Encode::decode('UTF-16BE', $str); # UTF-8 flag on
#                            Encode::from_to($str, 'UTF-16BE', 'utf8');
#                            utf8::decode($str) if ($is_utf8);
#                            $s .= $str;
                            @utf16 = ();
                        }
                        else {
                            if (scalar(@utf16)) {
                                error("surrogate pair expected");
                            }
                            $s .= chr(hex($u));
                        }
                    }
                    else{
                        $s .= $ch;
                    }
                }
                else{
                    if ($utf8 and $is_utf8) {
                        if( hex(unpack('H*', $ch))  > 255 ) {
                            error("malformed UTF-8 character in JSON string");
                        }
                    }

                    $s .= $ch;
                }
            }
        }

        error("Bad string (unexpected end)");
    }


    sub white {
        while( defined $ch  ){
            if($ch le ' '){
                next_chr();
            }
            elsif($ch eq '/'){
                next_chr();
                if($ch eq '/'){
                    1 while(defined(next_chr()) and $ch ne "\n" and $ch ne "\r");
                }
                elsif($ch eq '*'){
                    next_chr();
                    while(1){
                        if(defined $ch){
                            if($ch eq '*'){
                                if(defined(next_chr()) and $ch eq '/'){
                                    next_chr();
                                    last;
                                }
                            }
                            else{
                                next_chr();
                            }
                        }
                        else{
                            error("Unterminated comment");
                        }
                    }
                    next;
                }
                else{
                    error("Syntax error (whitespace)");
                }
            }
            else{
                last;
            }
        }
    }


    sub object {
        my $o = {};
        my $k;

        if($ch eq '{'){
            error() if (++$depth > $max_depth);
            next_chr();
            white();
            if($ch eq '}'){
                next_chr();
                return $o;
            }
            while(defined $ch){
                $k = ($bare and $ch ne '"' and $ch ne "'") ? bareKey() : string();
                white();

                if($ch ne ':'){
                    error("Bad object ; ':' expected");
                }

                next_chr();
                $o->{$k} = value();
                white();

                if($ch eq '}'){
                    next_chr();
                    return $o;
                }
                elsif($ch ne ','){
                    last;
                }
                next_chr();
                white();
            }

            error("Bad object ; ,or } expected while parsing object/hash");
        }
    }


    sub bareKey { # doesn't strictly follow Standard ECMA-262 3rd Edition
        my $key;
        while($ch =~ /[^\x00-\x23\x25-\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\x7F]/){
            $key .= $ch;
            next_chr();
        }
        return $key;
    }


    sub word {
        my $word =  substr($text,$at-1,4);

        if($word eq 'true'){
            $at += 3;
            next_chr;
            return $unmap ? 1 : new 'JSON::true';
        }
        elsif($word eq 'null'){
            $at += 3;
            next_chr;
            return $unmap ? undef : new 'JSON::null';
        }
        elsif($word eq 'fals'){
            $at += 3;
            if(substr($text,$at,1) eq 'e'){
                $at++;
                next_chr;
                return $unmap ? 0 : new 'JSON::false';
            }
        }

        $at--; # for error report

        error("Syntax error (word) 'null' expected")  if ($word =~ /^n/);
        error("Syntax error (word) 'true' expected")  if ($word =~ /^t/);
        error("Syntax error (word) 'false' expected") if ($word =~ /^f/);
        error("Syntax error (word) malformed json string, neither array, object, number, string or atom");
    }


    sub number {
        my $n    = '';
        my $v;

        if($ch eq '0'){
            my $peek = substr($text,$at,1);
            my $hex  = $peek =~ /[xX]/; # 0 or 1

            if($hex){
                ($n) = ( substr($text, $at+1) =~ /^([0-9a-fA-F]+)/);
            }
            else{ # oct
                ($n) = ( substr($text, $at) =~ /^([0-7]+)/);
            }

            if(defined $n and length($n)){
                if (!$hex and length($n) == 1) {
                   error("malformed number (leading zero must not be followed by another digit)");
                }
                $at += length($n) + $hex;
                next_chr;
                return $hex ? hex($n) : oct($n);
            }
        }

        if($ch eq '-'){
            $n = '-';
            next_chr;
            if (!defined $ch or $ch !~ /\d/) {
                error("malformed number (no digits after initial minus)");
            }
        }

        while($ch =~ /\d/){
            $n .= $ch;
            next_chr;
        }

        if($ch eq '.'){
            $n .= '.';

            next_chr;
            if ($ch !~ /\d/) { error("malformed number (no digits after decimal point)"); }
            else             { $n .= $ch; }

            while(defined(next_chr) and $ch =~ /\d/){
                $n .= $ch;
            }
        }

        if($ch eq 'e' or $ch eq 'E'){
            $n .= $ch;
            next_chr;

            if(defined($ch) and ($ch eq '+' or $ch eq '-' or $ch =~ /\d/)){
                $n .= $ch;
            }
            else {
                error("malformed number (no digits after exp sign)");
            }

            while(defined(next_chr) and $ch =~ /\d/){
                $n .= $ch;
            }

        }

        $v .= $n;

        return 0+$v;
    }


    sub array {
        my $a  = [];

        if ($ch eq '[') {
            error() if (++$depth > $max_depth);
            next_chr();
            white();
            if($ch eq ']'){
                next_chr();
                return $a;
            }
            while(defined($ch)){
                push @$a, value();
                white();
                if($ch eq ']'){
                    next_chr();
                    return $a;
                }
                elsif($ch ne ','){
                    last;
                }
                next_chr();
                white();
            }
        }

        error(", or ] expected while parsing array");
    }


    sub error {
        my $error  = shift;
        my $no_rep = shift;

        local $Carp::CarpLevel = 1;

        my $str = substr($text, $at);

        unless (length $str) { $str = '(end of string)'; }

        if ($no_rep) {
            Carp::croak "$error";
        }
        else {
            Carp::croak "$error, at character offset $at ($str)";
        }
    }

} # PARSE



###############################
# from JSON::XS
#
# sub JSON::true()  { \1 }
# sub JSON::false() { \0 }


sub JSON::true  () { new 'JSON::true'; }
sub JSON::false () { new 'JSON::false'; }
sub JSON::null  () { new 'JSON::null'; }

package JSON::NotString;
use overload (
    '""'   => sub { $_[0]->{str} },
    'bool' => sub { $_[0]->{value} },
);



package JSON::true;
use base qw(JSON::NotString);

sub new { bless { str => 'true', value => 1 }; }


package JSON::false;
use base qw(JSON::NotString);

sub new { bless { str => 'false', value => 0 }; }

package JSON::null;
use base qw(JSON::NotString);

sub new { bless { str => 'null', value => undef }; }


1;
__END__
=pod

=head1 NAME JSON::PP - An experimental JSON::XS compatible Pure Perl module.

=head1 SYNOPSIS

 use JSON::PP;

 $obj       = from_json($json_text);
 $json_text = to_json($obj);

 # or

 $obj       = jsonToObj($json_text);
 $json_text = objToJson($obj);

 $json = new JSON;
 $json_text = $json->ascii->pretty($obj);

=head1 DESCRIPTION

This module is L<JSON::XS> compatible Pure Perl module.
It requires Perl 5.8.

The global variables ($JSON::*) were abolished.

JSON::PP will be renamed JSON (JSON-2.0).

Many things including error handling are learned from L<JSON::XS>.

=head2 FEATURES

=over

=item * perhaps correct unicode handling?

This module knows how to handle Unicode (perhaps),
but not yet documents how and when it does so.

=item * round-trip integrity

This module solved the problem pointed out by XS
using L<B> module.

=item * strict checking of JSON correctness

I want to bring close to XS.
How do you want to carry out?

=item * slow

Compared to other JSON modules, this module does not compare
favourably in terms of speed. Very slowly!

=item * simple to use

This module became very simple.
Since its interface were anyway made the same as JSON::XS.


=item * reasonably versatile output formats

See to L<JSON::XS>.

=back

=head1 FUNCTIONS

=over

=item to_json

See to JSON::XS.
C<objToJson> is an alias.

=item from_json

See to JSON::XS.
C<jsonToObj> is an alias.


=back


=head1 METHODS

=over

=item new

Returns JSON::PP object.

=item ascii

See to JSON::XS.

=item utf8

See to JSON::XS.

=item pretty

See to JSON::XS.

=item indent

See to JSON::XS.
Strictly, this module does not carry out equivalent to XS.

 $json->indent(4);

is not the same as this:

 $json->indent();


=item space_before

See to JSON::XS.

=item space_after

See JSON::XS.

=item canonical

See to JSON::XS.
Strictly, this module does not carry out equivalent to XS.
This method can take a subref for sorting (see to L<JSON>).


=item allow_nonref

See to JSON::XS.

=item shrink

Not yet implemented.

=item max_depth

See to JSON::XS. 
Strictly, this module does not carry out equivalent to XS.

=item encode

See to JSON::XS.

=item decode

See to JSON::XS.


=item property

Accessor.

 $json->property(utf8 => 1); # $json->utf8(1);

 $value = $json->property('utf8'); # returns 1.


=item self_encode

See L<JSON>'s self convert.

=item deny_blessed_object

Not yet implemented.


=item UTF8_off

Not yet implemented.

=item allow_tied

Enable.

=back

=head1 TODO

=over

=item Want to work on Perl 5.6

This module uses Encode...

=item Document!

It is troublesome.

=item clean up

Under the cleaning.

=back


=head1 SEE ALSO

L<JSON>, L<JSON::XS>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

=cut
