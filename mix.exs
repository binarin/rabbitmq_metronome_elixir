defmodule RabbitmqMetronomeElixir.Mixfile do
  use Mix.Project

  def project do
    deps_dir = case System.get_env("DEPS_DIR") do
      nil -> "deps"
      dir -> dir
    end
    [app: :rabbitmq_metronome_elixir,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps_path: deps_dir,
     deps: deps(deps_dir),
     aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:logger, :rabbit, :amqp],
     mod: {RabbitMQ.Plugin.Metronome, []},
     env: [exchange: "metronome"],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps(deps_dir) do
    [
      {:amqp, git: "https://github.com/binarin/amqp"},
      # We use `true` as the command to "build" rabbit_common and
      # amqp_client because Erlang.mk already built them.
      {
        :rabbit_common,
        path: Path.join(deps_dir, "rabbit_common"),
        compile: "true",
        override: true
      },
      {
        :amqp_client,
        path: Path.join(deps_dir, "amqp_client"),
        compile: "true",
        override: true
      },
      {
        :rabbit,
        path: Path.join(deps_dir, "rabbit"),
        compile: "true",
        override: true
      },
    ]
  end

  defp aliases do
    [
      make_deps: [
        "deps.get",
        "deps.compile",
      ],
      make_app: [
        "compile",
      ],
      make_all: [
        "deps.get",
        "deps.compile",
        "compile",
      ],
    ]
  end
end
