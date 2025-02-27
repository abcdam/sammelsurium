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


sub fetch_update {
    my($self) = @_;

    my($mem, $alloc) = (_read_meminfo(), 0);
    $alloc -= $mem->{$_} for (qw(MemFree Buffers Cached));

    my $alloc_rel = 1 + $alloc / $mem->{MemTotal};

    $self->append_tokens([
        { label => 'mem_used' },
        { sep   => '%' },
        {
            value => sprintf '%3.1f', 100 * $alloc_rel
        }
    ]);
}


sub _read_meminfo {
    return {
        map {
            /^(\w+):\s+(\d+)/
              ? ($1 => $2)
              : ()
        } Path::Tiny::path('/proc/meminfo')->lines
    };
}

package main;
Memory_stats->run;
