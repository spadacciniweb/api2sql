use utf8;
package Api2sql::Schema::Master::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Api2sql::Schema::Master::Result::Token

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<token>

=cut

__PACKAGE__->table("token");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 valore

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "valore",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-01-29 10:34:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bO+0OTBDESpExgtw5DX90Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
