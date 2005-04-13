package JSONRPC;

 # halfway JSON-RPC server

use strict;
use JSON;

use vars qw($VERSION);

$VERSION = 0.3;


sub new {
	my $class = shift;
	my $self  = {};
	bless $self,$class;
}


# JSONRPC::Transport::XXX->disptch_to('MyApp')->handle();
# This module looks for the method from MyApp.pm.
# looks for a method from the corresponding package name when a client call it.
# At present, only the module name can be specified. 

sub dispatch_to {
	my $class = shift;
	my $self  = $class->new;
	my @srv   = @_;

	if(@srv){
		$self->{_dispatch_to} = [ @srv ] ;
		$self;
	}
	else{
		@{ $self->{_dispatch_to} };
	}
}


# to a reqeust from a response (subclass must have the implementation.)

sub handle { }


# get a request from client (subclass must have the implementation.)

sub requset { }


# return a response (subclass must have the implementation.)

sub response { }


# an error that should cut connection (subclass must have the implementation.)

sub invalid_request {}


# the process in case not making response (subclass must have the implementation.)

sub no_response {}


# return a mthod name and any parameters from JSON-RPC data structure.

sub get_request_data {
	my $self   = shift;
	my $js     = $self->{json_data};
	my $method = $js->{method} || '';
	my $params = $js->{params} || [];
	return ($method,$params);
}


# look for the method from module names set by the dispatch_to().

sub find_method {
	my $self   = shift;
	my $method = shift;

	no strict 'refs';

	for my $srv ( @{$self->{_dispatch_to}} ){
		if($srv->can($method)){
			my $func = *{"$srv\::$method"};
			return $func;
		}
	}

	return;
}

# execution of method : return value is JSON-RPC data struture.
# $func->($self,@$params) returns a scalar or a hash ref or an array ref.

sub handle_method {
	my $self   = shift;
	my ($method,$params) = $self->get_request_data();

	if(my $func = $self->find_method($method)){
		my $result = $func->($self,@$params);
		$self->set_response_data($result)
	}
	else{
		$self->set_err('No such a method.');
	}
}


# execution of notification

sub notification {
	my $self  = shift;
	my ($method,$params) = $self->get_request_data();

	if(my $func = $self->find_method($method)){
		$func->($self,@$params);
	}

	return 1;
}


# convert Perl data into JSON for a response.

sub set_response_data {
	my $self  = shift;
	my $value = shift;
	my $id    = $self->request_id;
	my $error = $self->error;

	if(!defined $value){ $value = JSON::Null; }
	if(!defined $error){ $error = JSON::Null; }

	my $result = {
		id     => $id,
		result => $value,
		error  => $error,
	};

	return objToJson($result);
}


# convert Perl data into JSON for an error response.

sub set_err {
	my $self  = shift;
	my $error = shift;
	my $id    = $self->request_id;

	my $result = {
		id     => $id,
		result => JSON::Null,
		error  => $error,
	};

	return objToJson($result);
}


# accessor of error object

sub error {
	my $self = shift;
	$self->{_error} = $_[0] if(@_ > 0);
	$self->{_error};
}


# accessor of id

sub request_id {
	my $self = shift;

	if(@_ > 0){
		$self->{_request_id} = $_[0];
		if(ref($self->{_request_id}) =~ /JSON/ and !defined $self->{_request_id}->{value}){
			$self->{_request_id} = undef;
		}
	}

	$self->{_request_id};
}


1;
__END__


=head1 NAME

 JSONRPC - (halfway) server implementation of JSON-RPC protocol

=head1 SYNOPSIS

 #--------------------------
 # In your application class
 package MyApp;

 sub own_method { # called by clients
     my ($server, @params) = @_; # $server is JSONRPC object.
     ...
     # return a scalar value or a hashref or an arryaref.
 }

 #--------------------------
 # In your main cgi script.
 use JSONRPC::Transport::HTTP;
 use MyApp;

 # Currently provides only CGI server
 use JSONRPC::Transport::HTTP;

 # a la XMLRPC::Lite
 JSONRPC::Transport::HTTP::CGI->disptch_to('MyApp')->handle();


=head1 DESCRIPTION

This module implementes JSON-RPC (L</http://json-rpc.org/>) server.
Most ideas were borrowed from L<XMLRPC::Lite>.
Currently C<JSONRPC> provides only CGI server function.


=head1 SEE ALSO

L</http://json-rpc.org/>
L<JSON>
L<XMLRPC::Lite>


=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

