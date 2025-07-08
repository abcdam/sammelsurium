#!/usr/bin/env perl
use v5.36.0;

package Volume_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use parent qw(TaskRunner IOActivity);
use constant SECTOR_SIZE => 512;


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
            dev_cfg_key => $mountpoint_id
        };
    }
    return \%dm;
} ## end sub _build_device_map


sub run {
    my $class = shift;
    my $self  = $class->init;
    $self->{dm} = $self->_build_device_map;

    my $show_opt = [qw(io_load space_used)];
    $self->{dm_lists} = { map {$_ => []} @$show_opt };
    while (my($dm_path, $cfg) = each %{ $self->{dm} }) {
        for (@$show_opt) {
            push @{ $self->{dm_lists}{$_} }, $dm_path
              if $cfg->{show}{$_}
        }}

    while (my($dm_path, $cfg) = each %{ $self->{dm} }) {
        my $rdev = (stat($dm_path))[6];
        my($major, $minor) = (int($rdev / 256), $rdev % 256);
        $cfg->{maj_min} = sprintf '%s:%s', $major, $minor;
    }
    $self->run_loop;
} ## end sub run


sub fetch_update {
    my($self) = @_;
    my $curr_stats = $self->_get_volume_activity;
    $self->_fetch_IO_update($curr_stats);
    say 'ok';
}


sub _get_volume_activity {
    my($self) = @_;
    return $self->_get_IO_activity({
        data_loader => sub {
            my $dm_dev = shift;
            my($line) =
              Path::Tiny::path(
                "/sys/dev/block/$self->{dm}{$dm_dev}{maj_min}/stat"
              )->lines;
            return $line;
        },
        data_parser => sub {
            return map {$_ * SECTOR_SIZE} (
                grep {length} split /\s+/, shift
            )[ 2, 6 ];
        }
    });
}

package main;
Volume_stats->run;
