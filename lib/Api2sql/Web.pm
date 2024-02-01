package Api2sql::Web;

use Dancer2 appname => 'Api2sql';
use Api2sql::Common qw(
    jsonRepl
    logDB
);
use Api2sql::Web::Api;
use Data::Dumper;
no if ($] >= 5.018), 'warnings' => 'experimental';

Api2sql->load_config(setting('appdir') . "/etc/api2sql.conf");

prefix '/';

any qr{(.+)} => sub {
    logDB(request)
        if $Api2sql::Config->{global}->{debug};
    pass;
};

get '/404' => sub {
    return jsonRepl({ code => 404,
                      repl => 'Not found... please go away'
                    });
};

any qr{.*} => sub {
    forward '/404';
};

true;
