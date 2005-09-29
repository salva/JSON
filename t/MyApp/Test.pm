
package MyApp::Test;

sub echo {
	my $server = shift;
	my ($arg)  = @_;
	return "$arg!";
}

sub double {
	my $server = shift;
	my ($arg)  = @_;
	return "$arg x $arg";
}

1;

