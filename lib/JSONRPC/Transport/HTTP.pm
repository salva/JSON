package JSONRPC::Transport::HTTP;

use strict;
use base qw(JSONRPC);
use vars qw($VERSION);

$VERSION = 0.3;

#
#
#

package JSONRPC::Transport::HTTP::Server;

use base qw(JSONRPC);
use JSON;

sub handle {
	my $self  = shift;

	unless(ref $self){ $self = $self->new(@_) }

	if( my $request = $self->request() ){
		my $js = jsonToObj($request) or return $self->invalid_request();

		$self->{json_data} = $js;

		if( defined $self->request_id($js->{id}) ){
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


sub new { 
	my $self = shift;
	unless (ref $self) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(@_);
	}
	return $self;
}


sub handle {
	my $self = shift->new;
	my $length = $ENV{'CONTENT_LENGTH'} || 0;

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
	print $q->header(-type => 'text/plain; charset=UTF-8');
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


1;
__END__

=head1 DESCRIPTION

This module is L<JSONRPC> subclass.
Most ideas were borrowed from L<XMLRPC::Lite>.
Currently C<JSONRPC> provides only CGI server function.


=head1 CAUTION

This module requires CGI.pm which version is more than 2.9.2.
(become a core module in Perl 5.8.1.)


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

