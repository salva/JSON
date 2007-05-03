package JSON::PP;

# JSON-2.0

use 5.005;
use strict;
use base qw(Exporter);
use overload;

use Carp ();
use B ();
#use Devel::Peek;

$JSON::PP::VERSION = '0.95';

@JSON::PP::EXPORT = qw(from_json to_json jsonToObj objToJson);

*jsonToObj = *from_json;
*objToJson = *to_json;

my $ENABLE_UTF16;


BEGIN {
    my @properties = qw(
            utf8 allow_nonref indent space_before space_after canonical  max_depth shrink
            allow_tied self_encode singlequote allow_bigint disable_UTF8 strict
            allow_barekey
    );

    # Perl version check, ascii() is enable?
    # Helper module may set @JSON::PP::_properties.
    if ($] >= 5.008) {
        require Encode;
        push @properties, 'ascii';

        $ENABLE_UTF16 = 1;

        if ($] == 5.008) {
            *utf8::is_utf8 = *Encode::is_utf8;
        }

        *JSON_encode_ascii  = *_encode_ascii;
    }
    else {
        my $helper = $] >= 5.006 ? 'JSON::PP56' : 'JSON::PP5005';
        eval qq| require $helper |;
        if ($@) { Carp::croak $@; }
        push @properties, @JSON::PP::_properties;
        $ENABLE_UTF16 = $JSON::PP::_ENABLE_UTF16;
    }

    for my $name (@properties) {
        eval qq|
            sub $name {
                \$_[0]->{$name} = defined \$_[1] ? \$_[1] : 1;
                \$_[0];
            }
        |;
    }

}



# Functions

my %encode_allow_method
     = map {($_ => 1)} qw/utf8 pretty allow_tied allow_nonref self_encode/;
my %decode_allow_method
     = map {($_ => 1)} qw/utf8 allow_nonref disable_UTF8 strict singlequote allow_bigint allow_barekey/;


sub to_json { # encode
    my ($obj, $opt) = @_;

    if ($opt) {
        my $json = JSON::PP->new->utf8;

        for my $method (keys %$opt) {
            $json->$method($opt->{$method}) if (exists $encode_allow_method{$method});
        }

        return $json->encode($obj);
    }
    else {
        return __PACKAGE__->new->utf8->encode($obj);
    }

}


sub from_json { # decode
    my ($obj, $opt) = @_;

    if ($opt) {
        my $json = JSON::PP->new->utf8;

        for my $method (keys %$opt) {
            $json->$method($opt->{$method}) if (exists $decode_allow_method{$method});
        }

        return $json->decode($obj);
    }
    else {
        __PACKAGE__->new->utf8->decode(shift);
    }
}


# Methods

sub new {
    my $class = shift;
    my $self  = {
        max_depth => 32,
        unmap     => 1,
        indent    => 0,
        fallback  => sub { encode_error('Invalid value. JSON can only reference.') },
    };

    bless $self, $class;
}


sub encode {
    my $self = shift;
    my $obj  = shift;

    return $self->encode_json($obj);
}


sub decode {
    my $self = shift;
    my $json = shift;

    return $self->decode_json($json);
}


# accessor

sub property {
    my ($self, $name, $value) = @_;

    if (@_ == 1) {
        Carp::croak('property() requires 1 or 2 arguments.');
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



###
### Perl => JSON
###

{ # Convert

    my $depth;
    my $max_depth;
    my $keysort;
    my $indent;
    my $indent_count;
    my $ascii;
    my $utf8;
    my $self_encode;
    my $disable_UTF8;

    sub encode_json {
        my $self = shift;
        my $obj  = shift;

        $indent_count = 0;
        $depth        = 0;

        ($indent, $ascii, $utf8, $self_encode, $max_depth, $disable_UTF8)
                     = @{$self}{qw/indent ascii utf8 self_encode max_depth disable_UTF8/};

        $keysort = !$self->{canonical} ? undef
                                       : ref($self->{canonical}) eq 'CODE' ? $self->{canonical}
                                       : $self->{canonical} =~ /\D+/       ? $self->{canonical}
                                       : sub { $a cmp $b };

        my $str  = $self->toJson($obj);

        if (!defined $str and $self->{allow_nonref}){
            $str = $self->valueToJson($obj);
        }

        encode_error("non ref") unless(defined $str);

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
                if ($self->{self_encode} and $obj->can('toJson')) {
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
                return $self->valueToJson($obj);
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

        encode_error("data structure too deep (hit recursion limit)")
                                         if (++$depth > $max_depth);

        $self->_tie_object($obj, \%res) if ($self->{allow_tied});

        my ($pre, $post) = $indent ? $self->_upIndent() : ('', '');
        my $del = ($self->{space_before} ? ' ' : '') . ':' . ($self->{space_after} ? ' ' : '');

        for my $k (keys %$obj) {
            my $v = $obj->{$k};
            $res{$k} = $self->toJson($v) || $self->valueToJson($v);
        }

        $self->_downIndent() if ($indent);

        return '{' . $pre
                   . join(",$pre", map { utf8::decode($_) if ($] < 5.008);
                     _stringfy($self, $_)
                   . $del . $res{$_} } _sort($self, \%res))
                   . $post
                   . '}';
    }


    sub arrayToJson {
        my ($self, $obj) = @_;
        my @res;

        encode_error("data structure too deep (hit recursion limit)")
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
        # SvTYPE is IV or NV?
        return $value # as is 
                if ($b_obj->FLAGS & 0x00010000 or $b_obj->FLAGS & 0x00020000);

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

            if ($type eq 'SCALAR' and defined $$value) {
                return   $$value eq '1' ? 'true'
                       : $$value eq '0' ? 'false' : encode_error("cannot encode reference.");
            }

            if ($type eq 'CODE') {
                encode_error("JSON can only reference.");
            }
            else {
                encode_error("cannot encode reference.");
            }

        }
        else {
            return $self->{fallback}->($value)
                 if ($self->{fallback} and ref($self->{fallback}) eq 'CODE');
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
        #"/"  => '\\/', # TODO
    );


    sub _stringfy {
        my ($self, $arg) = @_;

        $arg =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/eg;

        $arg =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

        if ($ascii) {
            $arg = JSON_encode_ascii($arg);
        }

        if ($utf8 or $disable_UTF8) {
            utf8::encode($arg);
        }

        return '"' . $arg . '"';
    }


    sub selfToJson {
        my ($self, $obj) = @_;
        return $obj->toJson($self);
    }


    sub encode_error {
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

        $pre = "\n" . $space x $indent_count;

        return ($pre,$post);
    }


    sub _downIndent { $_[0]->{indent_count}--; }

} # Convert



sub _encode_ascii {
    join('',
        map {
            chr($_) =~ /[\x00-\x08\x0b\x0e-\x1f]/ ?
                sprintf('\u%04x', $_) :
            $_ <= 127 ?
                chr($_) :
            $_ <= 65535 ?
                sprintf('\u%04x', $_) :
                join("", map { '\u' . $_ }
                        unpack("H4H4", Encode::encode('UTF-16BE', pack("U", $_))));
        } unpack('U*', $_[0])
    );
}


#
# JSON => Perl
#

# from Adam Sussman
use Config;
my $max_intsize = length(((1 << (8 * $Config{intsize} - 2))-1)*2 + 1) - 1;
#my $max_intsize = length(2 ** ($Config{intsize} * 8)) - 1;


{ # PARSE 

    my %escapes = ( #  by Jeremy Muhlich <jmuhlich [at] bitflood.org>
        b    => "\x8",
        t    => "\x9",
        n    => "\xA",
        f    => "\xC",
        r    => "\xD",
        '\\' => '\\',
        #'/'  => '/',
    );

    my $text; # json data
    my $at;   # offset
    my $ch;   # 1chracter
    my $len;  # text length (changed according to UTF8 or NON UTF8)

    my $is_utf8;
    my $depth;

    my $unmap;          # unmmaping
    my $utf8;           # 
    my $max_depth;      # max nest nubmer of objects and arrays
    my $allow_bigint;   # using Math::BigInt
    my $disable_UTF8;   # don't flag UTF8 on
    my $singlequote;    # loosely quoting
    my $strict;         # 

    # no effect
    my $allow_barekey;  # bareKey

    sub decode_json {
        my $self = shift;

        ($text, $at, $ch, $depth) = (shift, 0, '', 0);

        if (!defined $text or ref $text) {
            decode_error("malformed text data.");
        }

        $is_utf8 = 1 if (utf8::is_utf8($text));

        $len  = length $text;

        ($utf8, $unmap, $max_depth, $allow_bigint, $disable_UTF8, $strict, $singlequote, $allow_barekey)
                 = @{$self}{qw/utf8 unmap max_depth allow_bigint disable_UTF8 strict singlequote allow_barekey/};

        unless ($self->{allow_nonref}) {
            white();
            unless (defined $ch and ($ch eq '{' or $ch eq '[')) {
                decode_error('JSON text must be an object or array'
                       . ' (but found number, string, true, false or null,'
                       . ' use allow_nonref to allow this)', 1);
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
        return string() if($ch eq '"' or ($singlequote and $ch eq "'"));
        return number() if($ch eq '-');
        return $ch =~ /\d/ ? number() : word();
    }


    sub string {
        my ($i,$s,$t,$u);
        my @utf16;

        $s = ''; # basically UTF8 flag on

        if($ch eq '"' or ($singlequote and $ch eq "'")){
            my $boundChar = $ch if ($singlequote);

            OUTER: while( defined(next_chr()) ){

                if((!$singlequote and $ch eq '"') or ($singlequote and $ch eq $boundChar)){
                    next_chr();

                    if (@utf16) {
                        decode_error("missing low surrogate character in surrogate pair");
                    }

                    if($disable_UTF8) {
                        utf8::encode($s) if (utf8::is_utf8($s));
                    }
                    else {
                        utf8::decode($s);
                    }

                    return $s;
                }
                elsif($ch eq '\\'){
                    next_chr();
                    if(exists $escapes{$ch}){
                        $s .= $escapes{$ch};
                    }
                    elsif($ch eq 'u'){ # UNICODE handling
                        # JSON_decode_unicode();
                        my $u = '';

                        for(1..4){
                            $ch = next_chr();
                            last OUTER if($ch !~ /[0-9a-fA-F]/);
                            $u .= $ch;
                        }

                        unless ($ENABLE_UTF16) { # can't handle UTF-16
                            $s .= chr(hex($u));
                            next;
                        }

                        # U+10000 - U+10FFFF
                        # U+D800 - U+DBFF
                        if ($u =~ /^[dD][89abAB][0-9a-fA-F]{2}/) { # UTF-16 high surrogate?
                            push @utf16, $u;
                        }
                        # U+DC00 - U+DFFF
                        elsif ($u =~ /^[dD][c-fC-F][0-9a-fA-F]{2}/) { # UTF-16 low surrogate?
                            unless (scalar(@utf16)) {
                                decode_error("missing high surrogate character in surrogate pair");
                            }
                            push @utf16, $u;
                            my $str = pack('H4H4', @utf16);
                            $s .= Encode::decode('UTF-16BE', $str); # UTF-8 flag on
                            @utf16 = ();
                        }
                        else {
                            if (scalar(@utf16)) {
                                decode_error("surrogate pair expected");
                            }

                            $s .= chr(hex($u));
                        }
                    } # UNICODE handling
                    else{
                        $s .= $ch;
                    }
                }
                else{
                    if ($utf8 and $is_utf8) {
                        if( hex(unpack('H*', $ch))  > 255 ) {
                            decode_error("malformed UTF-8 character in JSON string");
                        }
                    }
                    elsif ($strict) {
                        if ($ch =~ /[\x00-\x1f\x22\x2f\x5c]/)  {
                            decode_error('invalid character');
                        }
                    }

                    $s .= $ch;
                }
            }
        }

        decode_error("Bad string (unexpected end)");
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
                            decode_error("Unterminated comment");
                        }
                    }
                    next;
                }
                else{
                    decode_error("Syntax decode_error (whitespace)");
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
            decode_error('json structure too deep (hit recursion limit)', )
                                                    if (++$depth > $max_depth);
            next_chr();
            white();
            if(defined $ch and $ch eq '}'){
                next_chr();
                return $o;
            }
            while(defined $ch){
                $k = ($allow_barekey and $ch ne '"' and $ch ne "'") ? bareKey() : string();
                white();

                if(!defined $ch or $ch ne ':'){
                    decode_error("Bad object ; ':' expected");
                }

                next_chr();
                $o->{$k} = value();
                white();

                last if (!defined $ch);

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

            decode_error("Bad object ; ,or } expected while parsing object/hash");
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

        $at--; # for decode_error report

        decode_error("Syntax decode_error (word) 'null' expected")  if ($word =~ /^n/);
        decode_error("Syntax decode_error (word) 'true' expected")  if ($word =~ /^t/);
        decode_error("Syntax decode_error (word) 'false' expected") if ($word =~ /^f/);
        decode_error("Syntax decode_error (word)" .
                        " malformed json string, neither array, object, number, string or atom");
    }


    sub number {
        my $n    = '';
        my $v;

        # According to RFC4627, hex or oct digts are invalid.
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
                   decode_error("malformed number (leading zero must not be followed by another digit)");
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
                decode_error("malformed number (no digits after initial minus)");
            }
        }

        while(defined $ch and $ch =~ /\d/){
            $n .= $ch;
            next_chr;
        }

        if(defined $ch and $ch eq '.'){
            $n .= '.';

            next_chr;
            if (!defined $ch or $ch !~ /\d/) {
                decode_error("malformed number (no digits after decimal point)");
            }
            else {
                $n .= $ch;
            }

            while(defined(next_chr) and $ch =~ /\d/){
                $n .= $ch;
            }
        }

        if(defined $ch and ($ch eq 'e' or $ch eq 'E')){
            $n .= $ch;
            next_chr;

            if(defined($ch) and ($ch eq '+' or $ch eq '-' or $ch =~ /\d/)){
                $n .= $ch;
            }
            else {
                decode_error("malformed number (no digits after exp sign)");
            }

            while(defined(next_chr) and $ch =~ /\d/){
                $n .= $ch;
            }

        }

        $v .= $n;

        if ($allow_bigint) { # from Adam Sussman
            require Math::BigInt;
            return Math::BigInt->new($v) if ($v !~ /[.eE]/ and length $v > $max_intsize);
        }

        return 0+$v;
    }


    sub array {
        my $a  = [];

        if ($ch eq '[') {
            decode_error('json structure too deep (hit recursion limit)', 1)
                                                        if (++$depth > $max_depth);
            next_chr();
            white();
            if($ch eq ']'){
                next_chr();
                return $a;
            }

            while(defined($ch)){
                push @$a, value();
                white();

                if (!defined $ch) {
                    last;
                }

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

        decode_error(", or ] expected while parsing array");
    }


    sub decode_error {
        my $error  = shift;
        my $no_rep = shift;
        my $str    = defined $text ? substr($text, $at) : '';

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
# Utilities
#

BEGIN {
    eval 'require Scalar::Util';
    unless($@){
        *JSON::PP::blessed = \&Scalar::Util::blessed;
    }
    else{ # This code is from Sclar::Util.
        # warn $@;
        eval 'sub UNIVERSAL::a_sub_not_likely_to_be_here { ref($_[0]) }';
        *JSON::PP::blessed = sub {
            local($@, $SIG{__DIE__}, $SIG{__WARN__});
            ref($_[0]) ? eval { $_[0]->a_sub_not_likely_to_be_here } : undef;
        };
    }
}


###############################
# from JSON::XS
#
# sub JSON::true()  { \1 }
# sub JSON::false() { \0 }


sub JSON::PP::true  () { 'JSON::true'->new; }
sub JSON::PP::false () { 'JSON::false'->new; }
sub JSON::PP::null  () { 'JSON::null'->new; }

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

=head1 NAME

JSON::PP - An experimental JSON::XS compatible Pure Perl module.

=head1 SYNOPSIS

 use JSON::PP;

 $obj       = from_json($json_text);
 $json_text = to_json($obj);

 # or

 $obj       = jsonToObj($json_text);
 $json_text = objToJson($obj);

 $json = new JSON;
 $json_text = $json->ascii->pretty($obj);

 # you can set options to functions.

 $json_text = to_json($obj, {ascii => 1, intend => 2});
 $obj       = from_json($json_text, {utf8 => 0});


=head1 DESCRIPTION

This module is L<JSON::XS> compatible Pure Perl module.
( Perl better than 5.008 is recommended)

Module variables ($JSON::*) were abolished.

JSON::PP will be renamed JSON (JSON-2.0).

Many things including error handling are learned from L<JSON::XS>.
For t/02_error.t compatible, error messages was copied partially from JSON::XS.


=head2 FEATURES

=over

=item * perhaps correct unicode handling

This module knows how to handle Unicode (perhaps),
but not yet documents how and when it does so.

In Perl5.6x, Unicode handling requires L<Unicode::String> module.

Perl 5.005_xx, Unicode handling is disable currenlty.


=item * round-trip integrity

This module solved the problem pointed out by JSON::XS
using L<B> module.

=item * strict checking of JSON correctness

I want to bring close to XS.
How do you want to carry out?

you can set C<strict> decoding method.

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

In Perl 5.6, this method requires L<Unicode::String>.
If you don't have Unicode::String,
the method is always set to false and warns.


=item utf8

See to JSON::XS.

Currently this module always handles UTF-16 as UTF-16BE.

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
By default, not 512 (JSON::XS) but 32.

=item encode

See to JSON::XS.

=item decode

See to JSON::XS.
In Perl 5.6, if you don't have Unicode::String,
the method can't handle UTF-16(BE) char and returns as is.


=item property

Accessor.

 $json->property(utf8 => 1); # $json->utf8(1);

 $value = $json->property('utf8'); # returns 1.


=item self_encode

See L<JSON/BLESSED OBJECT>'s I<self convert> function.


=item deny_blessed_object

Useless? Not yet implemented.


=item disable_UTF8

If this option is set, UTF8 flag in strings generated
by C<encode>/C<decode> is off.


=item allow_tied

Enable.


=item singlequote

Allows to decode single quoted strings.

Unlike L<JSON> module, this module does not encode
Perl string into single quoted string any longer.


=item allow_barekey

Allows to decode bare key of member.


=item allow_bigint

When json text has any integer in decoding more than Perl can't handle,
If this option is on, they are converted into L<Math::BigInt> objects.


=item strict

For JSON format, unescaped [\x00-\x1f\x22\x2f\x5c] strings are invalid and
JSON::XS decodes just like that. While this module can deocde thoese.
But if this option is set, the module strictly decodes.


=back


=head1 COMPARISON

Using a benchmark program in the JSON::XS (v1.11) distribution.

 module     |     encode |     decode |
 -----------|------------|------------|
 JSON::PP   |  11092.260 |   4482.033 |
 -----------+------------+------------+
 JSON::XS   | 341513.380 | 226138.509 |
 -----------+------------+------------+

In case t/12_binary.t (JSON::XS distribution).
(shrink of JSON::PP has no effect.)

JSON::PP takes 138 (sec).

JSON::XS takes 4.


=head1 TODO

=over

=item Document!

It is troublesome.

=item clean up

Under the cleaning.

=back


=head1 SEE ALSO

L<JSON>, L<JSON::XS>

RFC4627

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
