package JSON::PP5005;

use 5.005;
use strict;

my @properties;

$JSON::PP5005::VERSION = '0.02';

BEGIN {
    *JSON::PP::JSON_encode_ascii = *_encode_ascii;

    sub utf8::is_utf8 {
        1; # It is considered that UTF8 flag on for Perl 5.005.
    }

    sub utf8::encode (\$) {
    }

    sub utf8::decode (\$) {
    }

    sub JSON::PP::ascii {
        warn "ascii() is disable in Perl5.005.";
        $_[0]->{ascii} = 0; $_[0];
    }

    $JSON::PP::_ENABLE_UTF16 = 0;
}


sub _encode_ascii {
    # currently noop
}


1;
__END__

=pod

=head1 NAME

JSON::PP5005 - Helper module in using JSON::PP in Perl 5.005

=head1 DESCRIPTION

JSON::PP calls internally.

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

