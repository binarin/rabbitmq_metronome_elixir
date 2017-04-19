defmodule RabbitMQ.Plugin.Metronome do
  use Application
  def start(_type, _args) do
    RabbitMQ.Plugin.Metronome.Sup.start_link
  end

  defmodule Sup do
    use Supervisor
    def start_link do
      Supervisor.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
      children = [worker(RabbitMQ.Plugin.Metronome.Worker, [], restart: :permanent)]
      supervise(children, strategy: :one_for_one, )
    end
  end

  defmodule Worker do
    use GenServer
    @rk_format "~4.10.0B.~2.10.0B.~2.10.0B.~1.10.0B.~2.10.0B.~2.10.0B.~2.10.0B"

    defmodule State do
      defstruct channel: nil, exchange: nil
    end

    def start_link do
      GenServer.start_link(__MODULE__, :ok, name: {:global, __MODULE__})
    end

    def init(:ok) do
      {:ok, conn} = AMQP.Connection.open
      {:ok, chan} = AMQP.Channel.open(conn)
      {:ok, exchange} = Application.fetch_env(:rabbitmq_metronome_elixir, :exchange)
      :ok = AMQP.Exchange.declare chan, exchange, :topic
      fire()
      {:ok, %State{channel: chan, exchange: exchange}}
    end

    def handle_cast(:fire, state = %State{exchange: exchange, channel: channel}) do
      {date={year, month, day},{hour, min, sec}} = :erlang.universaltime()
      day_of_week = :calendar.day_of_the_week(date)
      routing_key = :erlang.list_to_binary(:io_lib.format(@rk_format, [year, month, day, day_of_week, hour, min, sec]))
      payload = routing_key
      AMQP.Basic.publish channel, exchange, routing_key, payload, content_type: "text/plain"
      :timer.apply_after(1000, __MODULE__, :fire, [])
      {:noreply, state}
    end

    def handle_cast(_, state) do
      {:noreply, state}
    end

    def terminate(_, %State{channel: channel}) do
      AMQP.Channel.close(channel)
      :ok
    end

    def fire() do
      GenServer.cast({:global, __MODULE__}, :fire)
    end

  end
end
