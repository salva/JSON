
use lib qw(t/);
use strict;
use Test::More;

BEGIN { plan tests => 29 };

use JSONRPC::Transport::HTTP;
use JSON;

my $rpc = JSONRPC::Transport::HTTP::CGI
                        ->dispatch_to('MyApp/Test/', 'MyApp/Test2/');
my $q   = new TestCGI;
my $io;

# Test1

$q->{url} = '/MyApp/Test2/';

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

$q->{url} = '/MyApp/Test/';
printout($rpc,\$io, query => $q);
is(jsonToObj($io)->{id},'httpReq', 'Test2');
is(jsonToObj($io)->{result},'this is test?!');
ok(! jsonToObj($io)->{error});

$json = {
	id     => "httpReq",
	method => "double",
	params => ["this is test?"]
};

$q->param( POSTDATA => objToJson($json) );

printout($rpc,\$io, query => $q);
is(jsonToObj($io)->{id},'httpReq', 'Test2-2');
is(jsonToObj($io)->{result},'this is test? x this is test?');
ok(! jsonToObj($io)->{error});
$q->{url} = '/MyApp/Test2/';

# Test3

undef $io;

$json = {
	id     => "httpReq",
	method => "echo",
	params => ["not POSTDATA"]
};
$q->param(json => objToJson($json));

printout($rpc,\$io, query => $q, paramName => 'json');
is(jsonToObj($io)->{id},'httpReq', 'Test3 paramName');
is(jsonToObj($io)->{result},'not POSTDATA');
ok(! jsonToObj($io)->{error});


# Test4

undef $io;

$q->{url} = '/MyApp/Test/';
printout($rpc,\$io, query => $q, paramName => 'json');
is(jsonToObj($io)->{id},'httpReq', 'Test4 paramName');
is(jsonToObj($io)->{result},'not POSTDATA!');
ok(! jsonToObj($io)->{error});

# Test5


$q->{url} = '/MyApp/Test3/';

printout($rpc,\$io, query => $q, paramName => undef);

is(jsonToObj($io)->{id},'httpReq', 'Test5 paramName => undef');
ok(!jsonToObj($io)->{result});
like(jsonToObj($io)->{error}, qr/no such a method/i);

# Test6

$json = {
	id     => "httpReq",
	method => "echo",
	params => ["this is test?"]
};

$q->param( POSTDATA => objToJson($json) );

$q->{url} = '/MyApp/Test/';

printout($rpc,\$io, query => $q, paramName => undef);
is(jsonToObj($io)->{id},'httpReq', 'Test6 paramName => undef');
is(jsonToObj($io)->{result},'this is test?!');
ok(! jsonToObj($io)->{error});

$q->{url} = '/MyApp/Test2/';

printout($rpc,\$io, query => $q, paramName => undef);
is(jsonToObj($io)->{id},'httpReq', 'Test6-2 paramName => undef');
is(jsonToObj($io)->{result},'this is test?');
ok(! jsonToObj($io)->{error});


# Test7

undef $io;
 $rpc = JSONRPC::Transport::HTTP::CGI->dispatch_to('TestServer');

$json->{method} = 'echo2';
$q->param(POSTDATA => objToJson($json));

printout($rpc,\$io, query => $q);

is(jsonToObj($io)->{id},'httpReq', 'Test7 no such a method');
ok(! jsonToObj($io)->{result});
like(jsonToObj($io)->{error}, qr/no such a method/i);


sub printout {
	my ($rpc, $ioref, @opts) = @_;
{
	$$ioref = '';
	local *STDOUT;
	tie *STDOUT, 'TestSTDOUT', $ioref;
	$rpc->handle(@opts);
}
#	print $$ioref,"\n";
	$$ioref =~ s/^.*?\015\012\015\012//s;

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

sub request_method { 'POST'; }

sub url { $_[0]->{url} }

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

