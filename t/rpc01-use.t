use Test;
use strict;
BEGIN { plan tests => 1 };
use JSONRPC::Transport::HTTP;
ok(1); # If we made it this far, we're ok.

END {
warn "\nJSONRPC::Transport::HTTP requires CGI.pm (>= 2.9.2)."
 if(CGI->VERSION < 2.92);
}

