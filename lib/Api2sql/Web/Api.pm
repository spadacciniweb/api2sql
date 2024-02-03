package Api2sql::Web::Api;

use Dancer2 appname => 'Api2sql';

use strict;
use warnings;
use Api2sql::Common qw(
    incrMemcached
    jsonRepl
    logDB

    tokens_rs
);
use Data::Dumper;
no if ($] >= 5.018), 'warnings' => 'experimental';

prefix '/api';

any qr{(.+)} => sub {
    logDB(request)
        if $Api2sql::Config->{global}->{debug};
    pass;
};

get '' => sub {
    return jsonRepl({ code => 200,
                      repl => 'Read the documentation'
                    });
};

get '/' => sub {
    return jsonRepl({ code => 200,
                      repl => 'Are you sure? Read the documentation'
                    });
};

get '/token' => sub {
    my @tokens = tokens_rs->search_rs({},{
        order_by     => { -desc => [qw/ valore /] },
        rows         => 3,
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
    })->all;
    return jsonRepl({ code => 200,
                      repl => \@tokens
                    });
};

post '/token' => sub {
    my $token = ( query_parameters->get('id') and
                  query_parameters->get('id') =~ /^\d+$/ 
                )
        ? query_parameters->get('id')
        : int(rand(1_000_000_000));

    incrMemcached($token);
    if (tokens_rs->search_rs({
          id => $token
        })->count
    ) {
        tokens_rs->update({
            valore => \'valore+1'
        });
        return jsonRepl({ code => 200,
                          repl => sprintf "Token %d incrementato", $token
                        });
    } else {
        tokens_rs->create({
            id     => $token,
            valore => 1,
        });
        return jsonRepl({ code => 200,
                          repl => sprintf "Token %d creato", $token
                        });
    }
};

true;
