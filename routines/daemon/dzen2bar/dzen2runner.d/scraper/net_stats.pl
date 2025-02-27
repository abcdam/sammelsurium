#!/usr/bin/env perl
use v5.36.0;

package Net_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use parent qw(TaskRunner IOActivity);


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;

    my $curr_stats = $self->_get_net_activity;
    $self->fetch_IO_update($curr_stats);
}


sub _get_net_activity {
    my($self) = @_;
    my @content = Path::Tiny::path('/proc/net/dev')->lines;
    return $self->_get_activity({
        data_loader => sub {
            my $iface_dev = shift;
            my($line) = grep {/$iface_dev/} @content;
            return $line;
        },
        data_parser => sub {
            return (grep {length} split /\s+/, shift)[ 1, 9 ];
        }
    });
}

package main;
Net_stats->run;
