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

    require Record
    import AMQP.Core
    Record.defrecordp :amqp_params_direct, :amqp_params_direct, Record.extract(:amqp_params_direct, from_lib: "amqp_client/include/amqp_client.hrl")
    Record.defrecordp :amqp_adapter_info, :amqp_adapter_info, Record.extract(:amqp_adapter_info, from_lib: "amqp_client/include/amqp_client.hrl")
    Record.defrecordp :amqp_msg, [props: p_basic(), payload: ""]

    defmodule State do
      defstruct channel: nil, exchange: nil
    end

    def start_link do
      GenServer.start_link(__MODULE__, :ok, name: {:global, __MODULE__})
    end

    def init(:ok) do
      direct_params = amqp_params_direct(
        username: :none,
        password: :none,
        virtual_host: "/",
        node: node(),
        adapter_info: amqp_adapter_info(),
        client_properties: [],
      )
      :io.format(:standard_error, "HO: ~p~n", [direct_params])
      {:ok, conn} = :amqp_connection.start(direct_params)
      {:ok, chan} = :amqp_connection.open_channel(conn)
      {:ok, exchange} = Application.fetch_env(:rabbitmq_metronome_elixir, :exchange)
      :amqp_channel.call(chan, exchange_declare(exchange: exchange, type: "topic"))
      fire()
      {:ok, %State{channel: chan, exchange: exchange}}
    end

    def handle_cast(:fire, state = %State{exchange: exchange, channel: channel}) do
      {date={year, month, day},{hour, min, sec}} = :erlang.universaltime()
      day_of_week = :calendar.day_of_the_week(date)
      routing_key = :erlang.list_to_binary(:io_lib.format(@rk_format, [year, month, day, day_of_week, hour, min, sec]))
      payload = routing_key

      properties = p_basic(content_type: "text/plain", delivery_mode: 1)
      basic_publish = basic_publish(exchange: exchange, routing_key: routing_key)
      content = amqp_msg(props: properties, payload: payload)
      :amqp_channel.call(channel, basic_publish, content)
      :timer.apply_after(1000, __MODULE__, :fire, [])
      {:noreply, state}
    end

    def handle_cast(_, state) do
      {:noreply, state}
    end

    def terminate(_, %State{channel: channel}) do
      :amqp_channel.close(channel)
      :ok
    end

    def fire() do
      GenServer.cast({:global, __MODULE__}, :fire)
    end

  end
end
