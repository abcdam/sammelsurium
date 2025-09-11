#!/usr/bin/env perl
package ConfigParser;
use v5.36.0;

use YAML::XS qw(LoadFile);
use Carp;


sub load {
    my($class, $opt) = @_;

    croak "config path required"
      unless $opt->{path};
    croak "Missing defaults path"
      unless $opt->{defaults};

    my $conf = LoadFile($opt->{path})
      or croak "Failed to load config @ $opt->{path}";


    my($defaults_root, @defaults_rest) = str2keys($opt->{defaults});
    my $defaults = $conf->{$defaults_root}
      or croak "Defaults root '$defaults_root' not found in config";

    $defaults = $defaults->{$_}
      // croak "key '$_' not found in defaults hash in config"
      for @defaults_rest;

    return bless {
        (conf => (_setup_self({
            raw => {
                defaults => $defaults,
                local    => $conf,
                select   => (
                    $opt->{base_key} //
                      croak 'base_key to use for lookup not set by caller'
                ),
            }
        }))),
    }, $class;
} ## end sub load


sub _setup_self {
    my $conf = shift;
    my( $select,
        $defaults,
        $local
    ) = @{ $conf->{raw} }{qw(select defaults local)};

    return (
        ! defined $defaults->{$select}
        ? croak "config file incomplete, missing '$select' key in defaults hash"
        : ! exists $local->{$select}
        ? croak "no config entry found for '$select'"
        :
          {
            local   => $local->{$select},
            default => $defaults->{$select},
          }
    );
}


sub get_param {
    my($self, $args)     = @_;
    my($path, $fallback) = @{$args}{qw(path fallback)};

    croak "path must be set"
      unless defined $path;

    return $self->{conf}{default}
      if $path eq '.';

    my @keys = str2keys($path);
    return
      xtract_val(
        $self->{conf}{local}, @keys
      ) //
      xtract_val(
        $self->{conf}{default}, @keys[ 1 .. $#keys ]
      ) //
      $fallback //
      croak "No match found for path '$path'";
} ## end sub get_param


sub xtract_val {
    my($hash, @keys) = @_;

    for my $key (@keys) {
        return unless defined $hash->{$key};
        $hash = $hash->{$key};
    }
    return $hash;
}


sub str2keys {return split /\./, shift // ()}
1;
