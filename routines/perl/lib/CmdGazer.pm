#!/usr/bin/env perl
use v5.36.0;

package CmdGazer;


use Carp;
use File::Which;
use IPC::Run qw(start new_chunker timeout harness);

my %INSTANCE;


## no critic (Variables::RequireLocalizedPunctuationVars)
$SIG{TERM} = $SIG{INT} = do {
    my %old_handlers = %SIG{qw(INT TERM)};
    sub {
        my $signal = shift;
        defined and $_->{terminate}->(force => 1)
          for delete @INSTANCE{ keys %INSTANCE };
        if (defined(my $oh = $old_handlers{$signal})) {
            return if $oh eq 'IGNORE';
            return $oh->($signal) if ref $oh eq 'CODE';
        }
        $SIG{$signal} = 'DEFAULT';
        kill $signal, $$;
    }
};

my $create = sub {
    my %OPT = @_;

    my @Q;
    my $h = harness $OPT{cmd}
      , '>'
      , new_chunker
      , sub {push @Q, @_}
      , my $block_clock = timeout $OPT{block_ms}, name => 'stalled pipe';

    my $term = sub {
        my %opt = @_;
        return 1 unless $h->pumpable;

# kill_kill docs:
#   Returns a 1 if the TERM was sufficient, or a 0 if KILL was required
# finish docs:
#   returns TRUE if all children returned 0 (and were not signaled and did  not coredump, ie ! $?), and FALSE otherwise
        eval {
            $opt{force}
              ? $h->kill_kill(grace => $OPT{kill_s})
              : eval {$h->finish}
              || (
                $h->pumpable
                ? $h->kill_kill(grace => $OPT{kill_s} / 2)
                : 1
              )
        }
    };


    my %internal = (terminate => $term);
    my $is_open  = sub {return 1 if $h->pumpable || @Q};


    my $await = sub {
        if (! @Q) {
            croak "cannot read from a closed stream"
              unless $h->pumpable;
            until (@Q or not $h->pumpable) {
                $block_clock->start;
                $h->pump;
                $block_clock->reset;
            }
            $term->() unless $h->pumpable;
        }
        return unless defined(local $_ = shift @Q);
        chomp;

        my $l = [ $OPT{parser}->($_) ];
        @$l > 1 || defined $l->[0]
          ? $l
          : []

    }; ## end $await = sub

    my $startup = sub {
        start $h;
        $block_clock->reset;
        sleep $OPT{start_ms} if $OPT{start_ms};
        $internal{is_open} = $is_open;
        $internal{await}   = $await;
        shift->()
    };
    $internal{is_open} = sub {$startup->($is_open)};
    $internal{await}   = sub {$startup->($await)};
    \%internal
}; ## end $create = sub

## PUBLIC
###
sub init {
    my %user_cfg = @_;

    croak "parser not a function"
      unless ref(my $parser = $user_cfg{parser} // sub {shift})
      eq 'CODE';

    my @cmd = @{ $user_cfg{cmd} }{qw(bin args)};

    push @cmd, do {
        local $_ = ref(my $args_ref = pop @cmd);
        croak "defined args not a list or scalar"
          unless /^(ARRAY|)$/;
        length
          ? @{$args_ref}
          : $args_ref // ()
    };

    croak "$cmd[0] not found"
      unless which $cmd[0]
      or -x -f $cmd[0];


    my $self = bless {}, __PACKAGE__;

    $INSTANCE{$self} = $create->(
        cmd      => \@cmd,
        parser   => $parser,
        block_ms => $user_cfg{grace_time}{block_ms} // 'inf',
        start_ms => $user_cfg{grace_time}{start_ms},
        kill_s   => $user_cfg{grace_time}{kill_s} || 5,
    );

    $self
} ## end sub init

sub is_looking {$INSTANCE{ shift() }{is_open}->()}

use overload
  '<>' => sub {$INSTANCE{ shift() }{await}->()},
  '""' => sub {overload::StrVal(shift)};
###
##


sub DESTROY {
    (do {
        delete $INSTANCE{ shift() }
          or return
    })->{terminate}->(force => 1)
}

1;
