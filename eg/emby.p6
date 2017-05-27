#!/usr/bin/env perl6

use WebService::Emby;
use Data::Dump;

my $emby = WebService::Emby.new;

say Dump $emby.get-server-info;

say Dump $emby.get-users;

