defmodule IASC.LocalCRDTRegistryClient do
  use GenServer
  require Logger

  alias IASC.{Random}
  alias IASCCustom.{HordeRegistry}

  @all_crdts_key :all_crtds
  @process_registry :delta_crdt_process_registry

  def start_link(_)do
    Logger.info("---- Starting #{__MODULE__} ----")
    node_name = current_node_registry
    GenServer.start_link(__MODULE__, %{name: node_name}, name: {:global, node_name})
  end

  @impl GenServer
  def init(%{name: name}) do
    :telemetry.execute(
      [:iasc_crdt, :registry, :up],
      %{registry_name: name, node: Node.self},
      %{}
    )

    {:ok, {}}
  end

  @impl GenServer
  def handle_call(:get_crdt_pids, _from, state) do
    {:reply, get_all_crdts_pids, state}
  end

  @impl GenServer
  def handle_cast({:add_crdt_pid, pid}, state) do
    :telemetry.execute(
      [:iasc_crdt, :crdt, :new],
      %{pid: pid},
      %{}
    )

    {:noreply, state}
  end

  defp get_all_registered_crdt_names do
    Registry.select(@process_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def get_all_crdts_pids() do
    Registry.select(@process_registry, [{{:_, :"$2", :_}, [], [:"$2"]}])
  end

  # --- Client functions --- #

  def notify_new_crdt(client_crdts, crdt_pid) do
    Enum.map(client_crdts, fn crdt_client -> 
      GenServer.cast(crdt_client, {:update_crdt_neighbour, crdt_pid}) 
    end)
  end

  def build_crdt_registry_name(node_name) do
    String.to_atom("LocalCRDTRegistry#{node_name}")
  end

  def get_all_crdt_pids_node(node_name) do
    pid = :global.whereis_name(build_crdt_registry_name(node_name))
    case pid do
      :undefined -> []
      pid -> GenServer.call(pid, :get_crdt_pids)
    end

  end

  def get_all_crtds_clients_cluster do
    Enum.flat_map(Random.cluster_nodes(), fn node_name -> get_all_crdt_pids_node(node_name) end)
  end

  def get_all_global_registries do
    Enum.map(Random.cluster_nodes(), fn node_name -> build_crdt_registry_name(node_name) end)
  end

  def current_node_registry do
    build_crdt_registry_name(Random.current_node)
  end

  def get_state_of_all_crdts_in_cluster do
    Enum.map(get_all_crtds_clients_cluster, fn a -> IASC.DeltaCRDT.get_map(a) end)
  end
end

# IASC.LocalCRDTRegistryClient.get_all_crdt_pids_node("node3")
# IASC.LocalCRDTRegistryClient.get_all_global_registries

# client = List.first(IASC.LocalCRDTRegistryClient.get_all_crtds_clients_cluster)
# GenServer.cast(client, {:put, "a", 2})
# IASC.LocalCRDTRegistryClient.get_state_of_all_crdts_in_cluster

