#!/usr/bin/env perl
use v5.36.0;

package Workspace_view;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use IPC::Run qw( start new_chunker );
use JSON::XS;
use parent 'TaskRunner';
use POSIX qw(strftime);

my @CMD     = (qw(i3-msg -t subscribe -m), qq(["workspace"]));
my $janitor = { cleanup => sub { } };    # noop until init complete

END {$janitor->{cleanup}->()}


sub create_queue_service {
    my @QUEUE;
    return {
        create_consumer => sub {
            my $harness = shift;
            sub {
                my($prev, $curr) = (-1, scalar @QUEUE);
                do {$harness->pump_nb; ($prev, $curr) = ($curr, scalar @QUEUE)}
                  until $curr == $prev;
                return unless $curr;
                [ splice(@QUEUE, 0) ]
            }
        },
        create_writer => sub {
            my $filtermap = shift;
            sub {
                return unless defined(my $event = $filtermap->(shift));
                push @QUEUE, $event;
            }

        }
    }
} ## end sub create_queue_service


sub create_filtermap {
    my %event_reg = map {$_ => $_} qw (focus empty init);
    my $step      = {
        filter => {
            defined => sub {
                return unless defined;
                chomp;
                return unless length;
                $_
            },
            relevant => sub {
                return unless
                  ref $_ eq 'HASH'
                  && defined $event_reg{ $_->{change} }
                  && defined $_->{current}{name};
                $_
            }
        },
        transform => {
            decode => sub {decode_json $_},
            reduce => sub {
                { kind => $_->{change}, label => $_->{current}{name} }
            }
        }
    };
    my @pipeline = (
        $step->{filter}{defined},
        $step->{transform}{decode},
        $step->{filter}{relevant},
        $step->{transform}{reduce}
    );
    sub {
        local $_ = shift;
        for my $f (@pipeline) {last unless defined($_ = $f->())}
        $_
    }
} ## end sub create_filtermap


sub setup_subscription {
    my $queue_svc     = create_queue_service();
    my $event_harness = start \@CMD
      , '>'
      , new_chunker    # split input stream by newline
      , $queue_svc->{create_writer}->(create_filtermap());
    return {
        collect_batch => $queue_svc->{create_consumer}->($event_harness),
        cleanup       => sub {
            return unless $event_harness->pumpable;
            $event_harness->finish
              or $event_harness->kill_kill
              or warn "harness cleanup failed: $@";
        }
    }
}


sub incremental_state_assembly {
    my($focus_snap, @loaded_space_keys) = @_;
    my %loaded_spaces_snap;
    @loaded_spaces_snap{@loaded_space_keys} = @loaded_space_keys;
    my $make = sub {
        my $new_focus = shift // $focus_snap;
        $focus_snap = $new_focus;
        (
            active_focus  => $new_focus,
            loaded_spaces => [ keys %loaded_spaces_snap ]
        )
    };
    return {
        focus => sub {$make->(shift)},
        empty => sub {delete $loaded_spaces_snap{ shift() }; $make->()},
        init  => sub {
            my $label = shift;
            $loaded_spaces_snap{$label} = $label;
            $make->($label)
        },
    }
} ## end sub incremental_state_assembly


sub to_update {
    my($batch, $active_focus, @loaded_spaces) = @_;

    my $apply_event = incremental_state_assembly($active_focus, @loaded_spaces);
    my %update      = map {$apply_event->{ $_->{kind} }->($_->{label})} @$batch;

    # focus change causes rerender
    return \%update unless $active_focus eq $update{active_focus};

    # added/removed workspaces in resolved update cause rerendering [p]
    my $sets_are_equal = do {
        my %A;
        @A{@loaded_spaces} = 1;
        my @B = @{ $update{loaded_spaces} };
        delete @A{@B};

        # B >= A ∧ |A| == |B| -> A = B
        ! %A && @B == @loaded_spaces
    };
    return if $sets_are_equal;
    \%update
} ## end sub to_update


sub _append_tokens {
    my $self = shift;
    my $s    = $self->{state};
    $self->append_tokens([
        { label => 'workspace' },
        { sep   => ': ' },
        map {{
            (   $_ eq $s->{active_focus}
                ? 'value'
                : 'label'
            ) => sprintf('%s ', $_)
        }} sort @{ $s->{loaded_spaces} }
    ]);
    $self
}


sub fetch_update {
    my $self = shift;
    return unless defined(
        my $batch = $self->gracious_eval(
            $self->{collect_batch},
            { errmsg => "unexpected batch collection error" }
        )
    );
    my $s      = $self->{state};
    my $update = to_update(
        $batch,
        $s->{active_focus},
        @{ $s->{loaded_spaces} }
    );
    return unless defined $update;
    $self->{state} = $update;
    $self->_append_tokens
}


sub _init_state {
    my $self = shift;
    my($active_focus, @loaded_spaces);
    for (@{ decode_json(`i3-msg -t get_workspaces`) }) {
        $active_focus = $_->{name} if $_->{focused};
        push @loaded_spaces, $_->{name};
    }
    $self->{state} = {
        loaded_spaces => \@loaded_spaces,
        active_focus  => $active_focus
    };
    $self->_append_tokens
}


sub run {
    my $class = shift;
    my $self  = $class->init->_init_state;

    my $subsc = setup_subscription();
    $self->{collect_batch} = $subsc->{collect_batch};
    $janitor->{cleanup}    = $subsc->{cleanup};
    $self->run_loop
}


package main;
Workspace_view->run;
