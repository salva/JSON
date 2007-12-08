use 5.00503;
use strict;
use ExtUtils::MakeMaker;

use lib qw( ./lib );

eval q| require JSON |;

die "lib/JSON.pm is not found. Check your files." if ($@);

my $version     = JSON->VERSION;
my $req_xs_ver  = JSON->require_xs_version;
my $has_xs      = 0;
my $message;

eval q| require JSON::XS |;

$has_xs = 1 unless ($@);


if ($has_xs) {
    my $xs_version = JSON::XS->VERSION;
    if ($xs_version >= $req_xs_ver) {
        $message = "You have JSON::XS (v.$xs_version), so JSON can work very fast!!";
    }
    else {
        $message = "Your JSON::XS version is $xs_version, but if you install v.$req_xs_ver,\n"
                 . "JSON will work faster.";
    }
}
else {
    $message = "If you install JSON::XS v.$req_xs_ver, it make JSON faster.";
}

print <<EOF;
Wellcome to JSON (v.$version)
=============================
$message

 ************************** CAUTION **************************
 * This is 'JSON version 2' and there are many differences   *
 * to version 1.xx                                           *
 * Please check your applications useing old version.        *
 *   See to 'INCOMPATIBLE CHANGES TO OLD VERSION' and 'TIPS' *
 *************************************************************


EOF


WriteMakefile(
    'NAME'		=> 'JSON',
    'VERSION_FROM'	=> 'lib/JSON.pm', # finds $VERSION
    'PREREQ_PM'		=> {
              'Test::More'  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/JSON.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
);
