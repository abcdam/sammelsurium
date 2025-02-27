#!/usr/bin/env perl
use v5.36.0;

package Localtime_view;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';
my @days = qw(Sun Mon Tue Wed Thu Fri Sat);


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;
    my($sec, $min, $hour, $mday, $mon, undef, $wday) = localtime();

    # Format: Day HH:MM:SS MM/DD
    my $update = sprintf '%s %02d:%02d:%02d %02d/%02d',
      $days[$wday], $hour, $min, $sec, $mon + 1, $mday;

    $self->append_tokens([
        { sep   => '~ ' },
        { value => $update },
        { sep   => ' ∽' }
    ]);
}

package main;
Localtime_view->run;
