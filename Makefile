PROJECT = rabbitmq_metronome
PROJECT_DESCRIPTION = Embedded Rabbit Metronome
PROJECT_MOD = rabbit_metronome

define PROJECT_ENV
[
	    {exchange, <<"metronome">>}
	  ]
endef

DEPS = rabbit_common rabbit amqp_client
TEST_DEPS = rabbitmq_ct_helpers rabbitmq_ct_client_helpers

DEP_PLUGINS = rabbit_common/mk/rabbitmq-plugin.mk

# FIXME: Use erlang.mk patched for RabbitMQ, while waiting for PRs to be
# reviewed and merged.

ERLANG_MK_REPO = https://github.com/rabbitmq/erlang.mk.git
ERLANG_MK_COMMIT = rabbitmq-tmp

include rabbitmq-components.mk
include erlang.mk