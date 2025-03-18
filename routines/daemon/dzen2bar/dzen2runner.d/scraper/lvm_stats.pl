#!/usr/bin/env perl
use v5.36.0;

package Lvm_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use parent qw(TaskRunner IOActivity);
use constant SECTOR_SIZE => 512;


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;
    my $curr_stats = $self->_get_lvm_activity;
    $self->_fetch_IO_update($curr_stats);
}


sub _get_lvm_activity {
    my($self) = @_;
    return $self->_get_IO_activity({
        data_loader => sub {
            my $dm_dev = shift;
            my($line) =
              Path::Tiny::path("/sys/block/$dm_dev/stat")->lines;
            return $line;
        },
        data_parser => sub {
            return map { $_ * SECTOR_SIZE } (
                grep {length} split /\s+/, shift
            )[ 2, 6 ];
        }
    });
}

package main;
Lvm_stats->run;
