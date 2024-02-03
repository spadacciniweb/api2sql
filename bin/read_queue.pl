#!/usr/bin/env perl

use strict;
use warnings;

use MongoDB;
use BSON::Types ':all';
use Cache::Memcached;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Api2sql;
use Api2sql::Common qw(
    logs_rs
    logsMongo_rs
    getMemcachedDump
);
use Data::Dumper;

Api2sql->load_config("$FindBin::Bin/.." . "/etc/api2sql.conf");

my $log = logs_rs->search_rs({},
                            {
                                columns      => [qw/ user_agent method ip ts /],
                                order_by     => { -desc => [qw/ ts / ] },
                                rows         => 1,
                            }
                           )->single;

printf "\n\n";
printf "### DB SQL ###\n";
printf "logs count: %s\n", logs_rs->count();
printf "last log:\n\tuser_agent: %s\n\tmethod: %s\n\tip: %s\n\tts: %s\n",
    $log->user_agent, $log->method, $log->ip, $log->ts;


my $cursor = logsMongo_rs->find()->sort ( { 'ts' => -1 } )->limit(1);
my $log_mongo = $cursor->next;
my $dt = bson_time( $log_mongo->{ts} )->as_datetime;

printf "\n\n";
printf "### DB NoSQL ###\n";
printf "logs count: %s\n", logsMongo_rs->estimated_document_count;
printf "last log:\n\tuser_agent: %s\n\tmethod: %s\n\tip: %s\n\tts: %s %s\n",
    $log_mongo->{user_agent}, $log_mongo->{method}, $log_mongo->{ip}, $dt->ymd, $dt->hms;

printf "\n\n";
printf "### Memcached ###\n";
printf "estimated tokens: %s\n", scalar keys %{getMemcachedDump() };
