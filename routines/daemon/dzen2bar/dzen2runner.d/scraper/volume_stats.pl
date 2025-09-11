#!/usr/bin/env perl
use v5.36.0;

package Volume_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use Filesys::DfPortable;
use parent qw(TaskRunner IOActivity);
use constant SECTOR_SIZE => 512;
use constant GiB_FACTOR  => 1024**3;
use Data::Dumper qw (Dumper);


sub run {
    my $class = shift;
    $class
      ->init
      ->_register_handlers
      ->_setup_run_config(sub {
        my($dm_path, $toggles) = @_;
        return {    # ADDITIONAL FEATURE CONFIG
            $toggles->{io_load} ? (sys_stat_file => _stat_fpath($dm_path)) : ()
        }
      })
      ->run_loop;
}


sub fetch_update {(shift)->_fetch_IO_update}


sub _stat_fpath {
    my $dm_path = shift;
    my $rdev    = (stat($dm_path))[6];
    my($major, $minor) = (int($rdev / 256), $rdev % 256);
    return sprintf '/sys/dev/block/%s:%s/stat', $major, $minor;
}


sub _build_device_map {
    my $self = shift;

    my $dev_cfgs = $self->{device_conf};
    local $self->{log}->context->{ctxt} = $dev_cfgs;

    # /proc/self/mounts format: # https://man.archlinux.org/man/fstab.5.en
    #   <device> <mountpoint> <fstype> <options> <dump> <pass>
    my %dm;
    for (Path::Tiny::path("/proc/self/mounts")->lines) {
        my($dev_mapping, $mountpoint_id) = split / /, $_;
        next
          unless exists $dev_cfgs->{$mountpoint_id}
          && defined $dev_cfgs->{$mountpoint_id}{label};

        $self->{log}->error(
            sprintf
              "Wrong configuration: MP '%s' is different from DM '%s' but both configured as keys in user config"
            , $mountpoint_id
            , $dev_mapping
        ) if $dev_cfgs->{$dev_mapping}
          && $mountpoint_id ne $dev_mapping;

        $dm{$dev_mapping} = {
            %{ $dev_cfgs->{$mountpoint_id} },
            mount_point => $mountpoint_id
        };
    }
    return \%dm;
} ## end sub _build_device_map


sub _get_current_stats {
    my($self, $dev_id) = @_;
    my($line) =
      Path::Tiny::path(
        $self->{dm}{$dev_id}{sys_stat_file}
      )->lines;
    my %curr_stats;
    @curr_stats{qw(in out)} = map {$_ * SECTOR_SIZE} (
        grep {length} split /\s+/, $line
    )[ 2, 6 ];
    return \%curr_stats;
}


sub _register_handlers {
    my $self            = shift;
    my $shared_handlers = $self->_get_shared_handlers;
    my $handler         = {
        io_load => sub {
            my($dev_id) = @_;
            my $curr = $self->_get_current_stats($dev_id);
            return $shared_handlers->{io_load}->($dev_id, $curr);
        },
    };

    $self->{handler} = $handler;
    return $self;
}

package main;
Volume_stats->run;
