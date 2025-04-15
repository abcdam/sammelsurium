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

my($CACHE_PATH)          = glob '~/.cache/i3/resti3_history.json';
my $CACHE                = setup_cache($CACHE_PATH);
my %AVAILABLE_WORKSPACES = get_available_workspaces();
my $USAGE
  = sprintf 'Usage: %s [-w <available workspace id>] [-c <layout config path>]'
  , basename $0;
### end section CONFIG

###
## section MAIN
#
my %opt;
GetOptions(
    'w=i' => sub {
        my($flag_id, $workspace_id) = @_;
        die "error: flag -w value must be an integer between 1 and 9.\n"
          if $workspace_id < 1 || $workspace_id > 9;
        die "error: workspace id '$workspace_id' already in use\n"
          if ! $AVAILABLE_WORKSPACES{$workspace_id};
        $opt{workspace} = $workspace_id;
    },
    'c=s' => sub {
        my($flag_id, $layout_config_path) = @_;
        my $err_prefix
          = "error: Config path passed with -c flag '$layout_config_path'";
        die "$err_prefix does not exist\n"
          unless -e $layout_config_path;
        die "$err_prefix must be a .json file\n"
          unless $layout_config_path =~ /\.json$/;
        $opt{layout_filep} = abs_path($layout_config_path);
    },
) or die "$USAGE\n";

my $config = handle_args(\%opt);
my $cmd    = [
    "i3-msg",
    "workspace $config->{workspace}; append_layout $config->{layout_filep}"
];
run $cmd, '>', '/dev/null'
  or die sprintf "Layout restoration failed for cmd '%s'. Caught: '%s'\n"
  , join ' ', @{$cmd}
  , $!;
update_cache($config);
### end section MAIN


###
## section FUN
#
sub setup_cache {
    my($cache_path) = @_;
    my $loaded_cache = {};
    if (-e $cache_path) {
        open(my $fh, '<', $cache_path)
          or die "Could not open cache file '$cache_path' $!";
        local $/;
        $loaded_cache = decode_json(<$fh>);
        close($fh);
    } else {
        make_path(dirname($cache_path));
    }
    return $loaded_cache;
}


sub get_available_workspaces {
    my $cmd = [ "i3-msg", "-t", "get_workspaces" ];
    my $output;
    die "Failed to get current i3 workspaces: $!"
      unless run $cmd, '>', \$output;

    my %available = map {
        $_ => 1
    } 1 .. 9;
    delete $available{ $_->{num} } for @{ decode_json($output) };
    die "All workspaces in use.\n"
      unless keys %available;
    return %available;
}


sub handle_args {
    my($workspace, $layout_filep) = @{ shift() }{qw(workspace layout_filep)};

    my $config = {};   # = { workspace => '', layout_filep => '', tstamp = '' };
    if (! $layout_filep) {
        my $entry_id = prompt_valid_cache_selection($CACHE);
        $config->{layout_filep} = $CACHE->{$entry_id}{layout_filep};
        if (! $workspace) {
            $config->{workspace} = $CACHE->{$entry_id}{workspace};
            $config->{tstamp}    = $entry_id;
        } else {
            delete $CACHE->{$entry_id};
        }}
    elsif (! $workspace) {
        $config->{workspace} = prompt_valid_workplace_selection();
    }
    $config->{layout_filep} //= $layout_filep;
    $config->{workspace}    //= $workspace;
    $config->{tstamp}       //= time;

    return $config;
} ## end sub handle_args


sub update_cache {
    my( $ws,
        $layout_config_filepath,
        $uid_timestamp
    ) = @{ shift() }{qw(workspace layout_filep tstamp)};
    $CACHE->{$uid_timestamp} = {
        layout_filep => $layout_config_filepath,
        workspace    => $ws
    };
    open(my $fh, '>', $CACHE_PATH)
      or die sprintf "Could not open cache file @ '%s': %s"
      , $CACHE_PATH
      , $!;
    say $fh encode_json($CACHE);
    close($fh);
}


sub prompt_valid_cache_selection {
    my($cache) = @_;
    my @timestamps = sort keys %$cache;
    my($sep, $pad) = ('-' x 80, ' ' x 8);

    die "Cache is empty\n" unless @timestamps > 0;
    printf "%3s %12s %19s\n", 'ID', 'Workspace', 'Location Config';
    say $sep;
    for (0 .. $#timestamps) {
        my $entry = $cache->{ $timestamps[$_] };
        printf "%3d %7d %s %s\n"
          , $_ + 1
          , $entry->{workspace}
          , $pad
          , $entry->{layout_filep};
    }
    say $sep;

    printf 'Select config [1-%s]: '
      , scalar @timestamps;

    chomp(my $input = <STDIN>);

    die "Invalid selection '$input'\n"
      unless $input =~ /^\d+$/
      && $input > 0
      && $input <= @timestamps;

    return $timestamps[ $input - 1 ];
} ## end sub prompt_valid_cache_selection


sub prompt_valid_workplace_selection {
    my @ws_ids = sort keys %AVAILABLE_WORKSPACES;
    say sprintf 'Available workspaces: %s'
      , join ', ', @ws_ids;
    print 'Set new workspace: ';

    chomp(my $input = <STDIN>);

    die "Invalid selection '$input'.\n"
      unless $AVAILABLE_WORKSPACES{$input};
    return $input;
}
### end section FUN
