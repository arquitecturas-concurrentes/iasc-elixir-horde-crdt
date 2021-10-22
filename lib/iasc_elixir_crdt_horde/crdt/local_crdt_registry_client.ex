defmodule IASC.LocalCRDTRegistryClient do
  use GenServer
  require Logger

  alias IASC.{Random}
  alias IASCCustom.{HordeRegistry}

  @all_crdts_key :all_crtds
  @process_registry :delta_crdt_process_registry

  def start_link(_)do
    Logger.info("---- Starting #{__MODULE__} ----")
    GenServer.start_link(__MODULE__, %{}, name: {:global, current_node_registry})
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_crdt_pids, _from, state) do
    {:reply, get_all_crdts_pids, state}
  end

  @impl GenServer
  def handle_cast({:add_crdt_pid, pid}, state) do
    Log.info("#{__MODULE__} Adding pid #{pid}")

    {:noreply, state}
  end

  defp get_all_registered_crdt_names do
    Registry.select(@process_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def get_all_crdts_pids() do
    Registry.select(@process_registry, [{{:_, :"$2", :_}, [], [:"$2"]}])
  end

  # --- Client functions --- #

  def build_crdt_registry_name(node_name) do
    String.to_atom("LocalCRDTRegistry#{node_name}")
  end

  def get_all_crdt_pids_node(node_name) do
    pid = :global.whereis_name(build_crdt_registry_name(node_name))
    GenServer.call(pid, :get_crdt_pids)
  end

  def get_all_crtds_cluster do
    Enum.flat_map(Random.cluster_nodes(), fn node_name -> get_all_crdt_pids_node(node_name) end)
  end

  def current_node_registry do
    build_crdt_registry_name(Random.current_node)
  end
end

# IASC.LocalCRDTRegistryClient.get_all_crdt_pids_node("node3")
# IASC.LocalCRDTRegistryClient.get_all_crtds_cluster