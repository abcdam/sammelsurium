#!/usr/bin/env perl
use v5.36.0;

package Cpu_stats;

BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';
my $previous_stats = [ (0) x _get_cpu_fields() ];

sub run {
    my $class = shift;
    $class->init->run_loop;
}

sub get_update {
    my ($self) = @_;

    my @current_stats = _get_cpu_fields();
    my @delta         = map { $current_stats[$_] - $previous_stats->[$_] }
      0 .. $#current_stats;
    my $freq_avg = _get_avg_freq();
    my $avg_freq_entry
      = $self->colorify_entry( 'ghz',     $self->{color}{label} ) . "@"
      . $self->colorify_entry( $freq_avg, $self->{color}{value} );

    my @cpu_stat_values
      = map { $self->colorify_entry( $_, $self->{color}{value} ) }
      _calculate_percentages(@delta);

    my @cpu_stat_labels
      = map { $self->colorify_entry( "${_}", $self->{color}{label} ) }
      qw(usr nice sys idl iozz hirq sirq);

    $previous_stats = \@current_stats;

    return $avg_freq_entry . ' ' . join ' ',
      map { $cpu_stat_labels[$_] . '%' . $cpu_stat_values[$_] }
      0 .. $#cpu_stat_labels;
} ## end sub get_update

sub _get_avg_freq {
    my $freqs = 0;
    my @paths = glob '/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq';
    for (@paths) {
        $freqs += ( Path::Tiny::path($_)->lines( { chomp => 1 } ) )[0];
    }
    return sprintf "%.2f", $freqs / ( 1000 * 1000 * scalar @paths );
}

sub _get_cpu_fields {
    my ($cpu_line) = Path::Tiny::path('/proc/stat')->lines( { count => 1 } );
    return ( split /\s+/, $cpu_line )[ 1 .. 7 ];
}

sub _calculate_percentages {
    my (@delta) = @_;
    my $total_time = 0;
    $total_time += $_ for @delta;
    return map { sprintf( "%.1f", 100 * $_ / $total_time ) } @delta;
}

package main;
Cpu_stats->run;
