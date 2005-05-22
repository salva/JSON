package JSONRPC::Transport::HTTP;

use strict;
use base qw(JSONRPC);
use vars qw($VERSION);

$VERSION = 0.9002;

#
#
#

package JSONRPC::Transport::HTTP::Server;

use base qw(JSONRPC);
use JSON;

use constant DEFAULT_CHARSET => 'UTF-8';

sub new { 
	my $self = shift;
	my %opt  = @_;

	unless (ref $self) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(%opt);
	}

	$self->{charset} = $opt{charset} || DEFAULT_CHARSET;
	return $self;
}


sub handle {
	my $self = shift;
	my $jp   = $self->{json_parser} || JSON::Parser->new;

	unless(ref $self){ $self = $self->new(@_) }

	if( my $request = $self->request() ){
		$self->{json_data}
		     = $jp->parse($request) or return $self->invalid_request();

		if( defined $self->request_id($self->{json_data}->{id}) ){
			my $res = $self->handle_method() or return $self->invalid_request();
			return $self->response($res);
		}
		else{
			$self->notification();
			$self->no_response();
		}
	}
	else{
		return $self->invalid_request();
	}
}

#
#
#

package JSONRPC::Transport::HTTP::CGI;

use CGI;
use base qw(JSONRPC::Transport::HTTP::Server);

use constant DEFAULT_CHARSET => 'UTF-8';


sub handle {
	my $self = shift->new;
	my %opt  = @_;
	my $length = $ENV{'CONTENT_LENGTH'} || 0;

	$self->{charset} = $opt{charset} if($opt{charset});

	$self->SUPER::handle();
}


sub request {
	my $self = shift;
	my $q    = new CGI;
	$self->{query} = $q;
	# check?
	my @name = $q->param;
	return (@name == 1) ? $q->param($name[0]) : undef;
}


sub response {
	my $self    = shift;
	my $resonse = shift;
	my $q       = $self->{query};
	my $charset = $self->{charset};
	print $q->header(-type => "text/plain; charset=$charset");
	print $resonse;
}


sub invalid_request {
	my $self = shift;
	my $q    = $self->{query} || new CGI;
	print $q->header(-status => '500');
}


sub no_response {
	my $self = shift;
	my $q    = $self->{query} || new CGI;
	print $q->header(-status => '200');
}


#
#
#

package JSONRPC::Transport::HTTP::Daemon;

use base qw(JSONRPC::Transport::HTTP::Server);

sub new {
	my $self = shift;

	unless (ref $self) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(@_);
	}

	eval q| require HTTP::Daemon; |;
	if($@){ die $@ }

	$self->{_daemon} ||= HTTP::Daemon->new(@_) or die;

	return $self;
}


sub handle {
	my $self = shift;
	my %opt  = @_;
	my $d    = $self->{_daemon} ||= HTTP::Daemon->new(@_) or die;

	$self->{charset} = $opt{charset} if($opt{charset});

	#print __PACKAGE__ . " is running...\n";

	while (my $c = $d->accept) {
		$self->{con} = $c;
		while (my $r = $c->get_request) {
			if ($r->method eq 'POST') {
				$self->{query} = $r->content;
				$self->SUPER::handle();
			}
			else {
				$self->invalid_request();
			}
			last;
		}
		$c->close;
	}
}

sub request {
	my $self = shift;
	return $self->{query};
}


sub response {
	my $self = shift;
	my $res  = shift;
	my $h    = HTTP::Headers->new;
	my $charset = $self->{charset};
	$h->header('Content-Type' => "text/plain; charset=$charset");
	$res = HTTP::Response->new(200 => undef, $h, $res);
	$self->{con}->send_response($res);
}


sub invalid_request {
	my $self = shift;
	my $res  = "Invalid request.";
	my $h    = HTTP::Headers->new;
	$self->{con}->send_error(500 => "Bad Request");
	return 0;
}


1;
__END__



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

 # a la XMLRPC::Lite
 JSONRPC::Transport::HTTP::CGI->dispatch_to('MyApp')->handle();


=head1 DESCRIPTION

This module is L<JSONRPC> subclass.
Most ideas were borrowed from L<XMLRPC::Lite>.
Currently C<JSONRPC> provides only CGI server function.


=head1 CHARSET
When the module returns response, its charset is UTF-8 by default.
You can change it via passing a key/value pair into handle().

 my %charset = (charset => 'EUC-JP');
 JSONRPC::Transport::HTTP::CGI->dispatch_to('MyApp')->handle(%charset);

=head1 CAUTION

This module requires CGI.pm which version is more than 2.9.2.
(become a core module in Perl 5.8.1.)


=head1 SEE ALSO

L<JSONRPC>
L<JSON>
L<XMLRPC::Lite>
L<http://json-rpc.org/>


=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

