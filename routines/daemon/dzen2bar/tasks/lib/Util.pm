package Util;

use strict;
use warnings;
use Exporter 'import';
use Config::Tiny;
use Carp;
use File::Basename qw(dirname);

my $config_path = dirname(__FILE__) . '/../../config.ini';
my $CONFIG = Config::Tiny->read($config_path)
    or croak "Failed to read config.ini: $!";
our @EXPORT = qw(colorize format_section get_interval);

my %colors = (
    red         => '^fg(#FF0000)',
    green       => '^fg(#00FF00)',
    blue        => '^fg(#0000FF)',
    yellow      => '^fg(#FFFF00)',
    reset       => '^fg()',
    orange      => '^fg(#D3A04D)',
    lblue       => '^fg(#6C99BB)',
    navy        => '^fg(#213555)',
    smooth_yellow => '^fg(#eed7a1)',
    pale_yellow => '^fg(#f7efd2)',
    sky_blue    => '^fg(#84cdee)',
    soft_olive  => '^fg(#ccd5ae)',
    pale_green  => '^fg(#e9edc9)'
);

sub colorize {
    my ($text, $color) = @_;
    return $colors{$color} . $text . $colors{reset};
}

sub format_section {
    my ($value, $color) = @_;
    return colorize($value, $color);
}

sub get_interval {
    my $caller = shift;
    my $interval = $CONFIG->{$caller}{interval};
    croak "No interval set for '$caller'" 
        unless defined $interval;
    return $interval;
}
1;