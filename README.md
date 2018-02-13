# BROKEN 

Need to fix
https://github.com/rabbitmq/rabbitmq-erlang-client/issues/91 and revert https://github.com/pma/amqp/issues/73#issuecomment-363725016

# RabbitMQ metronome plugin (Elixir version)

Re-implementation of https://github.com/rabbitmq/rabbitmq-metronome in
Elixir. This is the simplest possible plugin that can be used as a
base for making more complex ones. Some explanations available at https://binarin.ru/posts/2017-04-19-rabbit-plugins-in-elixir.html

This'll work only with RabbitMQ versions starting at ~3.7.0~.

## Running in an interactive mode

    make run-broker

Then you can test that everything works by issuing the following in that shell:

    rr(amqp_connection).
    {ok, Conn} = amqp_connection:start(#amqp_params_direct{}).
    {ok, C} = amqp_connection:open_channel(Conn).
    amqp_channel:call(C, #'queue.declare'{queue= <<"abc">>}).
    amqp_channel:call(C, #'queue.bind'{queue= <<"abc">>, exchange= <<"metronome">>, routing_key= <<"#">>}).
    amqp_channel:call(C, #'basic.consume'{queue= <<"abc">>}).
    %% after some time has passed
    flush().

## Running tests

    make ct

This will compile everything and then run Common Test suite that was
borrowed from original metronome plugin verbatim.
