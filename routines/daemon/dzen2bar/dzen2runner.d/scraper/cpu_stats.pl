#!/usr/bin/env perl
use v5.36.0;

package Cpu_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';
use constant GHz => 1000 * 1000;

# current Hz for each core on 1st line
my @PATHS = glob '/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq';


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;
    $self->append_tokens($self->_update_cpu_freq);
    $self->append_tokens($self->_update_alloc_times);
}


sub _update_cpu_freq {
    my $self            = shift;
    my $curr_freq       = _get_avg_freq();
    my $prev_freqs_buff = $self->{last_5_freqs} // [$curr_freq];

    unshift @{ $self->{last_5_freqs} }, $curr_freq;

    pop @{ $self->{last_5_freqs} }
      unless scalar @{ $self->{last_5_freqs} } < 5;

    my $freqs_sum = 0;
    $freqs_sum += $_ for @{ $self->{last_5_freqs} };

    return
      [
        { label => 'ghz' },
        { sep   => '@' },
        {
            value => sprintf '%.1f ',
            $freqs_sum / scalar @{ $self->{last_5_freqs} }
        },
      ];
} ## end sub _update_cpu_freq


sub _update_alloc_times {
    my $self = shift;

    my $curr_alloc_times  = _get_cpu_fields();
    my @state_alloc_prcts = _calculate_percentages([
        map {
            $curr_alloc_times->[$_] - $self->{prev_alloc_times}->[$_] // 0
        } 0 .. $#$curr_alloc_times
    ]);
    $self->{prev_alloc_times} = $curr_alloc_times;
    return [
        map {(
            { label => $_ },
            { sep   => '%' },
            {
                value => sprintf '%s ',
                shift @state_alloc_prcts
            }
        )} qw(usr nice sys idl iozz hirq sirq)
    ];
} ## end sub _update_alloc_times


sub _get_avg_freq {
    my $freqs = 0;
    $freqs += $_ for map {
        (   Path::Tiny::path($_)->lines({ chomp => 1, count => 1 })
        )[0]
    } @PATHS;
    return sprintf "%.2f"
      , $freqs / (GHz * scalar @PATHS);
}


sub _get_cpu_fields {
    my($cpu_line) = Path::Tiny::path('/proc/stat')->lines;
    return [ (split /\s+/, $cpu_line)[ 1 .. 7 ] ];
}


sub _calculate_percentages {
    my $delta      = shift;
    my $total_time = 0;
    $total_time += $_ for @{$delta};
    return map {
        sprintf '%.1f'
          , 100 * $_ / $total_time
    } @{$delta};
}

package main;
Cpu_stats->run;
