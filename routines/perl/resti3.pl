#!/usr/bin/env perl
# @abcdam
use v5.36.0;
###
## section CONFIG
#
use JSON::PP;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use File::Path qw(make_path);
use IPC::Run qw(run);

my $CACHE_PATH     = '~/.cache/i3/resti3_history.json';
my $CACHE          = setup_cache($CACHE_PATH);
my %active_wspaces = get_workspaces();
### end section CONFIG

###
## section MAIN
#
my $config = handle_args();
my @cmd    = (
    "i3-msg", "workspace $config->{workspace}; append_layout $config->{config}"
);
if (run \@cmd) {
    $CACHE->{ $config->{tstamp} } = { %{$config}{qw(config workspace)} };
    open(my $fh, '>', $CACHE_PATH)
      or die sprintf "Could not open cache file @ '%s': $!"
      , $CACHE_PATH;
    say $fh encode_json($CACHE);
    close($fh);
} else {
    die sprintf "Failed to load layout configuration using cmd: '%s'"
      , join ' ', @cmd;
}
### end section MAIN


###
## section FUN
#
sub get_workspaces {
    my @cmd = ("i3-msg", "-t", "get_workspaces");
    my $output;

    die "Failed to get current i3 workspaces: $?"
      unless run \@cmd, '>', \$output;
    return map {$_->{num} => $_} @{ decode_json($output) };
}


sub setup_cache {
    my($cache_path) = @_;
    my $loaded_cache = {};
    say($cache_path);
    if (! -e $cache_path) {
        make_path(dirname($cache_path));
    } else {
        open(my $fh, '<', $cache_path)
          or die "Could not open cache file '$cache_path' $!";
        local $/;
        $loaded_cache = decode_json(<$fh>);
        close($fh);
    }
    return $loaded_cache;
}


sub handle_args {
    my($workspace_id, $config_path);
    my $config;    # = { workspace => '', config => '', tstamp = '' };
    GetOptions(
        'w=i' => \$workspace_id,
        'c=s' => \$config_path,
    ) or die("Error in command line arguments\n");

    if (defined $workspace_id) {
        die "Option -w must be an integer between 1 and 9.\n"
          if $workspace_id < 1 || $workspace_id > 9;
        die "workspace '$workspace_id' already in use"
          if $active_wspaces{$workspace_id};
        $config->{workspace} = $workspace_id;
    }

    if (defined $config_path) {
        die "Option -c arg '$config_path' does not exist or is not a json\n"
          unless -e $config_path && $config_path =~ /\.json$/;
        $config->{config} = abs_path($config_path);
        if (! $config->{workspace}) {
            print "Available workspaces: ";
            print join ', '
              , grep {defined} map {$_ unless $active_wspaces{$_}} 1 .. 9;
            say "select an available worskpace number:";
            chomp(my $select = <STDIN>);
            die "Invalid selection '$select'.\n"
              unless $select =~ /^\d+$/
              && $select >= 1
              && $select <= @$CACHE
              && ! $active_wspaces{$select};
            $config->{workspace} = $select;
        }}
    elsif (! $config->{workspace}) {
        die "Cannot select from empty cache" if keys %$CACHE == 0;
        my @stamps  = sort {$a <=> $b} keys %$CACHE;
        my $padding = join '', (' ') x 14;
        my $sep     = join '', ('-') x 56;
        printf "%3s %20s %20s\n", 'ID', 'WORKSPACE_NUM', 'CONFIG_PATH';
        say $sep;
        for (my $i = 1; $i <= @stamps; $i++) {
            printf "%3s %14s %s %s\n"
              , $i
              , $CACHE->{ $stamps[ $i - 1 ] }{workspace}
              , $padding
              , $CACHE->{ $stamps[ $i - 1 ] }{config};
        }
        say $sep;
        print "select a cached config by [ID]: ";
        chomp(my $select = <STDIN>);
        die "Invalid selection '$select'.\n"
          unless $select =~ /^\d+$/
          && $select >= 1
          && $select <= @stamps;
        $config = {
            config    => $CACHE->{ $stamps[ $select - 1 ] }{config},
            workspace => $CACHE->{ $stamps[ $select - 1 ] }{workspace},
            tstamp    => $stamps[ $select - 1 ]
        };
    } ## end elsif (! $config->{workspace...})
    $config->{tstamp} = time unless $config->{tstamp};
    return $config;

} ## end sub handle_args
### end section FUN
