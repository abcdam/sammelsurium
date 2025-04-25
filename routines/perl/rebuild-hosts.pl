#!/usr/bin/env perl
use v5.36;
use Getopt::Long qw(:config bundling);
use File::Basename;
use File::Temp qw(tempfile);
use File::Copy qw(move copy);
use Cwd 'abs_path';

###
## section CONFIG
#
use constant HOSTS     => '/etc/hosts';
use constant HOSTS_BAK => '/usr/local/etc/hosts.bak';

die "not root\n" unless $< == 0;

my $USAGE = sprintf "%s\n  %s"
  , "Usage: $0 --restore | --directory <dir> [FRAGS]"
  , 'FRAGS: space-sepd filenames following .d dir drop-in config convention';

my $args = {};
GetOptions(
    'quiet-backup-check-fail|q' => $args->{quiet_backup},
    'restore|r'                 => sub {$args->{restore_backup} = 'restore'},
    'directory|d=s'             => $args->{frag_dir},
) or die $USAGE;
### end section CONFIG

###
## section MAIN
#
my $backup_handler = get_backup_handler($args->{quiet_backup});
my($succ, $err) = (
    $backup_handler->{ $args->{restore_backup} }
      // sub {(0)}
)->();

$succ and exit 0
  or ! $err
  or die "$err\n$USAGE\n";
defined $args->{frag_dir}
  or die "$USAGE\n";
-d $args->{frag_dir}
  or die "err: dir '$args->{frag_dir}' not found\n";

($succ, $err) = $backup_handler->{backup}->();
$err and die "$err\n";

my @frag_filenames = gather_fragments(
    abs_path $args->{frag_dir},
    [ map {$_ => 1} @ARGV ]
);
rebuild_hosts(HOSTS, \@frag_filenames);
exit 0;
### end section MAIN

###
## section FUN
#
sub get_backup_handler {
    my($noop_if_backup_exists) = @_;
    my $has_backup = -e HOSTS_BAK;

    return {
        restore => file_ops_factory({
            uid        => 'Restore',
            src        => HOSTS_BAK,
            dst        => HOSTS,
            act        => \&copy,
            constraint => sub {
                $has_backup ? undef : "no backup exists"
            }
        }),

        backup => file_ops_factory({
            uid        => 'Backup',
            src        => HOSTS,
            dst        => HOSTS_BAK,
            act        => \&copy,
            constraint => sub {
                ! $has_backup
                  ? undef
                  : $noop_if_backup_exists
                  ? ''
                  : "backup exists"
            }
        })
    };
} ## end sub get_backup_handler


sub get_deployer {
    my($tmp) = @_;

    return file_ops_factory({
        uid        => 'Deploy',
        src        => $tmp,
        dst        => HOSTS,
        act        => \&move,
        constraint => sub {-e $tmp ? undef : "temp file missing"},
    });
}


sub file_ops_factory {
    my($config) = @_;

    return sub {
        my $maybe_err = $config->{constraint}->();

        return (undef, "err: $config->{uid} constraint failure: $maybe_err")
          if $maybe_err;

        return (1) if defined $maybe_err;    # noop

        my $success =
          $config->{act}->(
            $config->{src},
            $config->{dst}
          );

        return (undef, "err: $config->{uid} failed: $!")
          unless $success;
        return (1);
    };
} ## end sub file_ops_factory


sub gather_fragments {
    my($dir, $fnames_expected) = @_;

    my %available = map {
        basename($_, ".conf") => $_
    } grep {-f $_} glob("$dir/*.conf");
    return (sort values %available)
      unless %$fnames_expected;
    my @wrong_fnames = keys %{
        +{  delete %{$fnames_expected}{
                grep {! exists $available{$_}} keys %{$fnames_expected}
            }
        }
    };

    return map {sprintf '%s/%s', $dir, $_} keys %{$fnames_expected}
      unless @wrong_fnames;

    die sprintf 'err: filenames not found: %s'
      , join ', ', @wrong_fnames;
} ## end sub gather_fragments


sub rebuild_hosts {
    my($hosts, $frags) = @_;

    my($fh, $tmp) = tempfile(UNLINK => 0);
    for my $f (@$frags) {
        say $fh "\n# --- from ", $f, " ---";
        open my $in, '<', $f
          or die "err: cannot read '$f': $!\n";
        print $fh $_ while <$in>;
        close $in;
    }

    close $fh;
    chmod 0644, $tmp
      or die "err: couldn't set 0644 permissions @ $tmp: $!";
    my($succ, $err) = get_deployer($tmp)->();
    $succ or die "$err\n";
}
### end section FUN
