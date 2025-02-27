#!/usr/bin/env perl
use v5.36.0;

package Audiovol_view;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';
my $PATTERN = qr/Sinks:.*?\*.*?([\d.]+)\]/s;


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;
    my $vol_prct = 100 * sprintf '%f'
      , qx(wpctl status) =~ /$PATTERN/;
    $self->append_tokens([
        { label => 'vol' },
        { sep   => '%' },
        { value => sprintf '%s ', $vol_prct }
    ]);
}

package main;
Audiovol_view->run;
