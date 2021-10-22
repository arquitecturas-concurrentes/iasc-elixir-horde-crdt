defmodule IascElixirCrdtHorde.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: IASCCustom.ClusterSupervisor]]},
      # Start the Telemetry supervisor
      IascElixirCrdtHordeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: IascElixirCrdtHorde.PubSub},
      # Start the Endpoint (http/https)
      IascElixirCrdtHordeWeb.Endpoint,
      # Start a worker by calling: IascElixirCrdtHorde.Worker.start_link(arg)
      # {IascElixirCrdtHorde.Worker, arg}
      # Horde Supervisor, Registry and Node Observer
      IASCCustom.HordeRegistry,
      IASCCustom.HordeSupervisor,
      IASCCustom.NodeObserver.Supervisor,
      # Local Registry Supervisor
      IASC.LocalCRDTRegistry.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IascElixirCrdtHorde.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IascElixirCrdtHordeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp topologies do
    [
      crdt_example_cluster: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end
