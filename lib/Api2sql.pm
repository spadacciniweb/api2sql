package Api2sql;
use Dancer2;

use Config::Tiny;
use Api2sql::Schema::Master;
use File::Basename qw(basename);
use FindBin;

our $appname = basename($0);
$appname =~ s/\.pl$//;
our $home = "$FindBin::Bin/..";

our $Config;
sub load_config {
    my $class = shift;
    my ($file) = @_;
    $Config = Config::Tiny->read($file) || Config::Tiny::errstr();
}

true;
