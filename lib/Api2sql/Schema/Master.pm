use utf8;
package Api2sql::Schema::Master;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-01-29 10:31:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jIzTXbKbpswhfBs/HnJjOQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
# cd lib ; dbicdump -o debug=1 Api2sql::Schema::Master 'dbi:mysql:dbname=api2sql_ib' api2sql_user api2sql_pwd  ; cd ..

sub connection {
    my $self = shift;
    my $cfg = $Api2sql::Config->{master_db};
    return $self->next::method({
        dsn => sprintf('DBI:mysql:database=%s;host=%s;port=%d;mysql_server_prepare=0;mysql_enable_utf8mb4=1',
            $cfg->{name}, $cfg->{host}, $cfg->{port}),
            user => $cfg->{user},
            password => $cfg->{pass},
            mysql_enable_utf8mb4 => 1,
    });
}

1;
