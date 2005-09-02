
use strict;
use Test::More;

BEGIN { plan tests => 14 };

use JSONRPC::Transport::HTTP;
use JSON;


my $rpc = JSONRPC::Transport::HTTP::CGI->dispatch_to('TestServer');
my $q   = new TestCGI;
my $io;

# Test1

isa_ok($rpc, 'JSONRPC::Transport::HTTP::CGI');
isa_ok($q, 'CGI');

my $json = {
	id     => "httpReq",
	method => "echo",
	params => ["this is test?"]
};

$q->param( POSTDATA => objToJson($json) );

printout($rpc,\$io, query => $q);
is(jsonToObj($io)->{id},'httpReq', 'Test1');
is(jsonToObj($io)->{result},'this is test?');
ok(! jsonToObj($io)->{error});

# Test2

undef $io;

$json = {
	id     => "httpReq",
	method => "echo",
	params => ["not POSTDATA"]
};
$q->param(json => objToJson($json));

printout($rpc,\$io, query => $q, paramName => 'json');
is(jsonToObj($io)->{id},'httpReq', 'Test2 paramName');
is(jsonToObj($io)->{result},'not POSTDATA');
ok(! jsonToObj($io)->{error});

# Test3

undef $io;

printout($rpc,\$io, query => $q, paramName => undef);

is(jsonToObj($io)->{id},'httpReq', 'Test3 paramName => undef');
is(jsonToObj($io)->{result},'this is test?');
ok(! jsonToObj($io)->{error});


# Test4

undef $io;
 $rpc = JSONRPC::Transport::HTTP::CGI->dispatch_to('TestServer');

$json->{method} = 'echo2';
$q->param(POSTDATA => objToJson($json));

printout($rpc,\$io, query => $q);

is(jsonToObj($io)->{id},'httpReq', 'Test4 no such a method');
ok(! jsonToObj($io)->{result});
like(jsonToObj($io)->{error}, qr/no such a method/i);


sub printout {
	my ($rpc, $ioref, @opts) = @_;
	local *STDOUT;
	tie *STDOUT, 'TestSTDOUT', $ioref;
	$rpc->handle(@opts);
}

#######################################

package TestSTDOUT;

sub TIEHANDLE {
	my $class = shift;
	my $var   = shift;

	bless $var, $class;
}

sub PRINT {
	my $self = shift;
	my $data = shift;

	return 1 if(defined $data and $data =~ /Content-Type/i);

	$$self .= $data;
	return 1;
}

#######################################

package TestServer;

sub echo {
	my $server = shift;
	my ($arg)  = @_;
	return $arg;
}

#######################################

package TestCGI;

use base qw(CGI);

sub new { bless {}, shift; }

sub param {
	my $self = shift;
	my ($name,$value) = @_;

	if(@_ == 0){
		return keys %{ $self->{testdata} };
	}
	elsif(@_ == 1){
		return $self->{testdata}->{$_[0]};
	}
	else{
		return $self->{testdata}->{$_[0]} = $_[1];
	}
}

