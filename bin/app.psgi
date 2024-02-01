#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


use Api2sql;
use Api2sql::Web;

Api2sql->to_app;
