package Api2sql::Common;

use strict;
use warnings;
use JSON;
use MongoDB;
use DateTime;
use Try::Tiny;
use Data::Dumper;
use Hash::Merge::Simple qw/ merge /;
no if ($] >= 5.018), 'warnings' => 'experimental';

use base qw(Exporter);
our @EXPORT_OK = qw(
    jsonRepl
    logDB

    tokens_rs
    logs_rs
    logsMongo_rs
);

my $Master;
my $MasterMongo;

sub master () {
    $Master ||= Api2sql::Schema::Master->connect;
    return $Master;
}

sub masterMongo () {
    $MasterMongo ||= MongoDB::MongoClient->new( 
        host => $Api2sql::Config->{mongo_db}->{host},
        port => $Api2sql::Config->{mongo_db}->{port},
    )->get_database( $Api2sql::Config->{mongo_db}->{name} );
    return $MasterMongo;
}

sub tokens_rs { return master->resultset('Token') }
sub logs_rs { return master->resultset('Log') }

sub logsMongo_rs { return masterMongo->get_collection( 'log' ) }

sub jsonRepl {
    return $Api2sql::Config->{global}->{dev}
        ? to_json(shift, {utf8 => 1, pretty => 1})
        : JSON->new->encode(shift);
}

sub logDB {
    my ($request) = @_;
    if ($Api2sql::Config->{global}->{debug}) {
        my %log = (
            ip         => $request->env->{'HTTP_X_FORWARDED_FOR'} || $request->env->{'HTTP_X_REAL_IP'} || $request->env->{'REMOTE_ADDR'} || $request->address,
            user_agent => $request->env->{'HTTP_USER_AGENT'},
            method     => $request->method,
            path       => $request->path,
            dump       => encode_json($request->params),
        );
        logs_rs->create(\%log);

        logsMongo_rs->insert_one( merge \%log,
                                        { "ts" => DateTime->now }
                                );
    }
    return undef;
}

1;
