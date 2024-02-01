use utf8;
package Api2sql::Schema::Master::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Api2sql::Schema::Master::Result::Log

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<logs>

=cut

__PACKAGE__->table("logs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ip

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_agent

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 method

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=head2 path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 dump

  data_type: 'mediumtext'
  is_nullable: 1

=head2 ts

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: 'current_timestamp()'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ip",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_agent",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "method",
  { data_type => "varchar", is_nullable => 1, size => 7 },
  "path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "dump",
  { data_type => "mediumtext", is_nullable => 1 },
  "ts",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "current_timestamp()",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-01-29 10:34:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q2IQgYQTaItzSKoXcrW7Ww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
