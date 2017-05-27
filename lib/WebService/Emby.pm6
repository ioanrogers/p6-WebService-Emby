use v6;

unit class WebService::Emby;

use HTTP::UserAgent;
use URI;
use Data::Dump;
use JSON::Fast;
use Digest::SHA;

has HTTP::UserAgent $!ua = HTTP::UserAgent.new(
    throw-exceptions => True,
    # debug            => True,
    useragent        => 'p6-WebService-Emby',
);

has Str $!auth-token;
has Str $!user-id;
has $!device-id = '/etc/machine-id'.IO.slurp.chomp;

my URI $base_url .= new('http://192.168.1.253:8096');

method http-get(Str $path) {
    my $url = URI.new("$base_url/$path");
    say "GET $url";

    my $res;

    if ($!auth-token.defined) {
        $res = $!ua.get($url, bin => False,
            Accept => 'application/json',
            X-Emby-Authorization => "MediaBrowser Client='p6-WebService-Emby', Device='Roku Ultra', DeviceId=$!device-id, Version='2.24'",
            X-MediaBrowser-Token => $!auth-token,
        );
    } else {
        $res = $!ua.get($url, bin => False,
            Accept => 'application/json',
            X-Emby-Authorization => "MediaBrowser Client='p6-WebService-Emby', Device='Roku Ultra', DeviceId=$!device-id, Version='2.24'",
        );
    }

    # if (!$res->{success}) {
    #     die sprintf "%i %s: %s", $res->{status}, $res->{reason},
    #       $res->{headers}->{'x-application-error-code'};
    # }

    my %data = from-json $res.decoded-content;
    return %data;
}

method http-delete(Str $path) {
    my $url = URI.new("$base_url/$path");
    say "DELETE $url";

    my $res = $!ua.delete($url,
        Accept => 'application/json',
        X-Emby-Authorization => "MediaBrowser Client='p6-WebService-Emby', Device='Roku Ultra', DeviceId=$!device-id, Version='2.24'",
        X-MediaBrowser-Token => $!auth-token,
    );

    my %data = from-json $res.decoded-content;
    return %data;
}


method http-post(Str $path, *%data) {
    my $url = URI.new("$base_url/$path");
    say "POST $url";

    my $res = $!ua.post(
        $url,
        %data,
        Accept => 'application/json',
        X-Emby-Authorization => "MediaBrowser Client='p6-WebService-Emby', Device='Roku Ultra', DeviceId=$!device-id, Version='2.24'",
    );

    my $data = from-json $res.decoded-content;
    return $data;
}

method get-server-info {
    return self.http-get('system/info/public');
}

method get-users {
    return self.http-get('users/public');
}

sub buf-to-hex { [~] $^buf.list».fmt: "%02x" }

method login (Str $username, Str $password = '') {
    my $password_hash = buf-to-hex(sha1 $password);
    my $data = self.http-post('users/authenticatebyname', username => $username, password => $password_hash );

    $!auth-token = $data<AccessToken>;
    $!user-id = $data<SessionInfo><UserId>;

    return;
}

method get-user-views(Str $user_id) {
    my %data = self.http-get("users/$user_id/views");
    return %data<Items>.flat;
}

method get-watched-episodes(Str $user-id, Str $parent-id) {
    my %data = self.http-get("users/$user-id/items?IsPlayed=true&Recursive=true&IncludeItemTypes=Episode&LocationTypes=FileSystem&ParentId=$parent-id");
    return %data<Items>.flat;
}

method delete-item(Str $id) {
    return self.http-delete("items/$id");
}
