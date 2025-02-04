#!/usr/bin/env perl
use v5.36.0;
package Memory_stats;
BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';

sub run {
    my $class = shift;
    $class->init->run_loop;
}

sub get_update {
    my ($self) = @_;
    my $mem = _read_meminfo();
    my $used = $mem->{MemTotal} - $mem->{MemFree} - $mem->{Buffers} - $mem->{Cached};
    my $usage_pct = sprintf("%3.1f", 100 * $used / $mem->{MemTotal});
    my $label = $self->colorify_entry('mem_used', $self->{color}{label});
    my $value = $self->colorify_entry($usage_pct, $self->{color}{value});
    return $label . '%' . $value;
}

sub _read_meminfo {
    my %mem;
    my @mem_lines = Path::Tiny::path('/proc/meminfo')->lines();
    for (@mem_lines) {
        /^(\w+):\s+(\d+)/;
        $mem{$1} = $2;
    }
    return \%mem;
}

package main;
Memory_stats->run;