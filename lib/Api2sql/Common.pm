package Api2sql::Common;

use strict;
use warnings;
use Cache::Memcached;
use JSON;
use MongoDB;
use DateTime;
use Try::Tiny;
use Data::Dumper;
use Hash::Merge::Simple qw/ merge /;
no if ($] >= 5.018), 'warnings' => 'experimental';

use base qw(Exporter);
our @EXPORT_OK = qw(
    getMemcachedDump
    incrMemcached
    jsonRepl
    logDB

    tokens_rs
    logs_rs
    logsMongo_rs
);

my $Master;
my $MasterMongo;
my $Memcached;

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

sub memcached () {
    $Memcached ||= new Cache::Memcached {
        servers => [ split ',', $Api2sql::Config->{memcached}->{servers} ],
        debug   => 0,
    };
    return $Memcached;
}

sub tokens_rs { return master->resultset('Token') }
sub logs_rs { return master->resultset('Log') }

sub logsMongo_rs { return masterMongo->get_collection( 'log' ) }

sub getMemcachedDump {
    my $hGetSlabs = memcached->stats( ['slabs'] );
    my @id_slabs = ();
    foreach (split /\n/, $hGetSlabs->{hosts}->{'127.0.0.1:11211'}->{slabs}) {
        my ($stats, undef) = split /:/;
        push @id_slabs, $1
            if $stats =~ /^STAT (\d+)/ and
               not($1 ~~ @id_slabs);
    }
    my @keys = ();
    foreach my $id_slabs (@id_slabs) {
        my $cmd_cachedump = sprintf 'cachedump %s 0', $id_slabs;
        my $hGetSlab = memcached->stats( [$cmd_cachedump] );
        foreach (split /\n/, $hGetSlab->{hosts}->{'127.0.0.1:11211'}->{$cmd_cachedump} ) {
            push @keys, $1
                if $_ =~ /^ITEM (.+) \[/;
        }
    }
    my $hKey = memcached->get_multi(@keys);

    return $hKey;
}

sub incrMemcached {
    my $token = shift;

    my $val = memcached->get($token);

    if ($val) {
        $Memcached->incr($token);
    } else {
        $Memcached->set($token, 1);
    }

    return undef;  
}

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
