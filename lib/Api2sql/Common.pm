package Api2sql::Common;

use strict;
use warnings;
use Cache::Memcached;
use JSON;
use DBI;
use MongoDB;
use DateTime;
use Try::Tiny;
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
my $dbhMongo;
my $dbhMemcached;
my $dbhSQLite;

sub master () {
    $Master ||= Api2sql::Schema::Master->connect;
    return $Master;
}

sub dbhMongo () {
    $dbhMongo ||= MongoDB::MongoClient->new( 
        host => $Api2sql::Config->{mongo_db}->{host},
        port => $Api2sql::Config->{mongo_db}->{port},
    )->get_database( $Api2sql::Config->{mongo_db}->{name} );
    return $dbhMongo;
}

sub dbhMemcached () {
    $dbhMemcached ||= new Cache::Memcached {
        servers => [ split ',', $Api2sql::Config->{memcached}->{servers} ],
        debug   => 0,
    };
    return $dbhMemcached;
}

sub dbhSQLite () {
    unless ($dbhSQLite) {
        $dbhSQLite = DBI->connect(
            sprintf "dbi:SQLite:dbname=%s",
                (join '/', $Api2sql::home, $Api2sql::Config->{sqlite}->{db})
        ) or die $DBI::errstr;
        if ($Api2sql::Config->{sqlite}->{fast}) {
            $dbhSQLite->do("PRAGMA synchronous = OFF");
            $dbhSQLite->do("PRAGMA cache_size = 1000000");
            $dbhSQLite->do("PRAGMA journal_mode = OFF");
            #$dbhSQLite->do("PRAGMA locking_mode = EXCLUSIVE");
            $dbhSQLite->do("PRAGMA temp_store = MEMORY");
        }
        buildSQLite($dbhSQLite);
    }
    return $dbhSQLite;
}

sub buildSQLite () {
    my $dbhSQLite = shift;
    my $stmt = qq(CREATE TABLE IF NOT EXISTS logs (
                   id         INTEGER PRIMARY KEY AUTOINCREMENT,
                   ip         VARCHAR(255),
                   user_agent VARCHAR(255),
                   method     VARCHAR(7),
                   path       VARCHAR(255),
                   dump       TEXT,
                   ts         DATETIME
               ); 
            );
    my $rv = $dbhSQLite->do($stmt);
}

sub tokens_rs { return master->resultset('Token') }
sub logs_rs { return master->resultset('Log') }

sub logsMongo_rs { return dbhMongo->get_collection( 'log' ) }

sub getMemcachedDump {
    my $hGetSlabs = dbhMemcached->stats( ['slabs'] );
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
        my $hGetSlab = dbhMemcached->stats( [$cmd_cachedump] );
        foreach (split /\n/, $hGetSlab->{hosts}->{'127.0.0.1:11211'}->{$cmd_cachedump} ) {
            push @keys, $1
                if $_ =~ /^ITEM (.+) \[/;
        }
    }
    my $hKey = dbhMemcached->get_multi(@keys);

    return $hKey;
}

sub incrMemcached {
    my $token = shift;

    my $val = dbhMemcached->get($token);

    if ($val) {
        $dbhMemcached->incr($token);
    } else {
        $dbhMemcached->set($token, 1);
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
                                )
            if $Api2sql::Config->{mongo}->{enabled};
        logSQLITE(\%log)
            if $Api2sql::Config->{sqlite}->{enabled};
    }
    return undef;
}

sub logSQLITE {
    my $log = shift;
    my $sth = dbhSQLite->prepare(q{
        INSERT INTO logs (ip, user_agent, method, path, dump, ts) VALUES (?, ?, ?, ?, ?, DateTime('now'))
    });
    $sth->execute($log->{ip}, $log->{user_agent}, $log->{method},
                  $log->{path}, $log->{dump}
                 );

    return undef;
}

1;
