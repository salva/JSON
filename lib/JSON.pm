package JSON;

use strict;
use base qw(Exporter);
use JSON::Parser;
use JSON::Converter;

@JSON::EXPORT = qw(objToJson jsonToObj);

use vars qw($AUTOCONVERT $VERSION);

$VERSION     = 0.98;
$AUTOCONVERT = 1;

my $parser; # JSON => Perl
my $conv;   # Perl => JSON

sub new { bless {}, shift; }


sub jsonToObj {
	my $self = shift;
	my $js   = shift;

	unless(ref($self)){
		$js = $self;
		$parser ||= new JSON::Parser;
		$parser->jsonToObj($js);
	}
	else{
		$self->{parser} ||= ($parser ||= JSON::Parser->new);
		$self->{parser}->jsonToObj($js);
	}
}


sub objToJson {
	my $self = shift || return;
	my $obj  = shift;

	unless(ref($self) =~ /JSON/){
		$obj = $self;
		$conv ||= new JSON::Converter;
		$conv->objToJson($obj);
	}
	else{
		$self->{conv} ||= ($conv ||= JSON::Converter->new);
		$self->{conv}->objToJson($obj);
	}
}


#
# NON STRING DATA
#

sub Number {
	my $num = shift;
	if(!defined $num or $num !~ /^-?(0|[1-9][\d]*)(\.[\d]+)?$/){
		return undef;
	}
	bless {value => $num}, 'JSON::NotString';
}

sub True {
	bless {value => 'true'}, 'JSON::NotString';
}

sub False {
	bless {value => 'false'}, 'JSON::NotString';
}

sub Null {
	bless {value => undef}, 'JSON::NotString';
}



1;

__END__

=pod

=head1 NAME

JSON - parse and convert to JSON (JavaScript Object Notation).

=head1 SYNOPSIS

 use JSON;

 $obj = {
    id   => ["foo", "bar", { aa => 'bb'}],
    hoge => 'boge'
 };

 $js  = objToJson($obj);
 $obj = jsonToObj($js);

 # OOP

 my $json = new JSON;

 $js  = $json->objToJson({id => 'foo', method => 'echo', params => ['a','b']});
 $obj = $json->jsonToObj($js);


=head1 DESCRIPTION

This module converts between JSON (JavaScript Object Notation) and Perl
data structure into each other.
For JSON, See to http://www.crockford.com/JSON/.


=head2 MAPPING

 JSON {"param" : []}
  => Perl {'param' => []};

 JSON {"param" : {}}
  => Perl {'param' => {}};

 JSON {"param" : "string"}
  => Perl {'param' => 'string'};

 JSON {"param" : null}
  => Perl {'param' => bless( {'value' => undef}, 'JSON::NotString' )};

 JSON {"param" : true}
  => Perl {'param' => bless( {'value' => 'true'}, 'JSON::NotString' )};

 JSON {"param" : false}
  => Perl {'param' => bless( {'value' => 'false'}, 'JSON::NotString' )};

 JSON {"param" : -1.23}
  => Perl {'param' => bless( {'value' => '-1.23'}, 'JSON::NotString' )};

These JSON::NotString objects are overloaded so you don't care about.
Perl's C<undef> is converted to 'null'.

=head2 AUTOCONVERT

By default $JSON::AUTOCONVERT is true.

Perl {num => 10.02}
   => JSON {"num" : 10.02} (not {"num" : "10.02"})

But set false value with $JSON::AUTOCONVERT:

Perl {num => 10.02}
   => JSON {"num" : "10.02"} (not {"num" : 10.02})

You can explicitly sepcify:

 $obj = {
 	id     => JSON::Number(10.02),
 	bool1  => JSON::True,
 	bool2  => JSON::False,
 	noval  => JSON::Null,
 };

 $json->objToJson($obj);
 # {"noval" : null, "bool2" : false, "bool1" : true, "id" : 10.02}

C<JSON::Number()> returns C<undef> when an argument invalid format.

=head1 Methods

C<new>, C<objToJson>, C<jsonToObj>.

=head2 EXPORT

C<objToJson>, C<jsonToObj>.

=head1 SEE ALSO

L<http://www.crockford.com/JSON/>
L<JSON::Parser>
L<JSON::Converter>


=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


