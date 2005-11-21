
use strict;
use Test::More;

BEGIN { plan tests => 13 };

use JSONRPC::Transport::HTTP;
use JSON;


my $rpc = JSONRPC::Transport::HTTP::CGI->dispatch_to('TestServer');
my $q   = new TestCGI;
my $io;

my $json = {
	id     => "httpReq",
	method => "echo",
	params => [JSON::True, JSON::False, JSON::Null],
};

$q->param(json => objToJson($json));

like($q->param('json'), qr{"params":\[true,false,null\]}, "check1");
like($q->param('json'), qr{"id":"httpReq"}, "check2");
like($q->param('json'), qr{"method":"echo"}, "check3");

printout($rpc,\$io, query => $q, paramName => 'json');


my $obj = jsonToObj($io)->{result};

isa_ok($obj->[0],'JSON::NotString');
isa_ok($obj->[1],'JSON::NotString');
isa_ok($obj->[2],'JSON::NotString');

ok($obj->[0]);
ok(!$obj->[1]);
ok(!$obj->[2]);

{ local $JSON::UnMapping = 1;

printout($rpc,\$io, query => $q, paramName => 'json');

my $obj = jsonToObj($io)->{result};

is($obj->[0],1);
is($obj->[1],0);
is($obj->[2],undef);

}


$q->param(json => q|{aaa}|);
printout($rpc,\$io, query => $q, paramName => 'json');
ok(1);


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
	my (@arg)  = @_;
	return [@arg];
}

#######################################

package TestCGI;

use base qw(CGI);

sub new { bless {}, shift; }

sub request_method { 'POST'; }

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

