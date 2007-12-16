package JSON::PP56;

use 5.006;
use strict;

my @properties;

$JSON::PP56::VERSION = '1.02';

BEGIN {
    sub utf8::is_utf8 {
        my $len =  length $_[0]; # char length
        {
            use bytes; #  byte length;
            return $len != length $_[0]; # if !=, UTF8-flagged on.
        }
    }

    sub utf8::upgrade {
        ; # noop;
    }

    sub utf8::downgrade {
        ; # noop;
    }

    sub utf8::encode (\$) { # UTF8 flag off
        ${$_[0]} = pack("C*", unpack("C*", ${$_[0]}));
    }

    sub utf8::decode (\$) { # UTF8 flag on
        if ( _is_valid_utf8(${$_[0]}) ) {
            ${$_[0]} = pack("U*", unpack("U*", ${$_[0]}));
        }
    }

    *JSON::PP::JSON_PP_encode_ascii      = \&_encode_ascii;
    *JSON::PP::JSON_PP_encode_latin1     = \&_encode_latin1;
    *JSON::PP::JSON_PP_decode_surrogates = \&JSON::PP::_decode_surrogates;
    *JSON::PP::JSON_PP_decode_unicode    = \&JSON::PP::_decode_unicode;

    push @JSON::PP::_properties, 'ascii', 'latin1';
}



sub _encode_ascii {
    join('',
        map {
            $_ <= 127 ?
                chr($_) :
            $_ <= 65535 ?
                sprintf('\u%04x', $_) : sprintf('\u%x\u%x', JSON::PP::_encode_surrogates($_));
        } _unpack_emu($_[0])
    );
}


sub _encode_latin1 {
    join('',
        map {
            $_ <= 255 ?
                chr($_) :
            $_ <= 65535 ?
                sprintf('\u%04x', $_) : sprintf('\u%x\u%x', JSON::PP::_encode_surrogates($_));
        } _unpack_emu($_[0])
    );
}


sub _unpack_emu { # for Perl 5.6 unpack warnings
    return   !utf8::is_utf8($_[0]) ? unpack('C*', $_[0]) 
           : _is_valid_utf8($_[0]) ? unpack('U*', $_[0])
           : unpack('C*', $_[0]);
}


sub _is_valid_utf8 {
    my $str = $_[0];
    my $is_utf8;

    while ($str =~ /(?:
          (
             [\x00-\x7F]
            |[\xC2-\xDF][\x80-\xBF]
            |[\xE0][\xA0-\xBF][\x80-\xBF]
            |[\xE1-\xEC][\x80-\xBF][\x80-\xBF]
            |[\xED][\x80-\x9F][\x80-\xBF]
            |[\xEE-\xEF][\x80-\xBF][\x80-\xBF]
            |[\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]
            |[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]
            |[\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]
          )
        | (.)
    )/xg)
    {
        if (defined $1) {
            $is_utf8 = 1 if (!defined $is_utf8);
        }
        else {
            $is_utf8 = 0 if (!defined $is_utf8);
            if ($is_utf8) { # eventually, not utf8
                return;
            }
        }
    }

    return $is_utf8;
}


1;
__END__

=pod

=head1 NAME

JSON::PP56 - Helper module in using JSON::PP in Perl 5.6

=head1 DESCRIPTION

JSON::PP calls internally.

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

