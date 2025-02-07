#!/usr/bin/env perl
package ConfigParser;
use v5.36.0;

use YAML::Tiny qw(LoadFile);
use Carp;

sub load {
    my ( $class, $path, %opt ) = @_;

    croak "config path required"
      unless $path;
    croak "Missing defaults path"
      unless $opt{defaults};

    my $self = LoadFile($path)
      or croak "Failed to load config @ $path";

    $self->{base_key} = $opt{base_key}
      // croak "base_key to use for look up not set";

    my @defaults_path = str2keys( $opt{defaults} );
    my $defaults_conf = $self->{ $defaults_path[0] };
    shift @defaults_path;
    $defaults_conf = $defaults_conf->{$_}
      // croak "key '$_' not found in defaults hash in config"
      for @defaults_path;
    $self->{defaults} = $defaults_conf;
    return bless $self, $class;
} ## end sub load

sub get_param {
    my ( $self, $args )     = @_;
    my ( $path, $fallback ) = @$args{qw( path fallback )};

    croak "path must be set"
      unless defined $path;
    return $self->{defaults}{ $self->{base_key} }
      if $path eq '.';

    my @keys = str2keys($path);

    return xtract_val( $self->{ $self->{base_key} }, @keys )
      // xtract_val( $self->{defaults}{ $self->{base_key} },
        @keys[ 1 .. $#keys ] )
      // $fallback
      // croak "No match found for path '$path'";
}

sub xtract_val {
    my ( $hash, @keys ) = @_;
    for (@keys) {
        return
          unless exists $hash->{$_} && defined $hash->{$_};
        $hash = $hash->{$_};
    }
    return $hash;
}

sub str2keys {
    return split /\./, shift
      // ();
}
1;
