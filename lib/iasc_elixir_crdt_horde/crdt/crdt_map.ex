defmodule IASC.DeltaCRDT do
  use GenServer
  require Logger

  alias IASC.{Random, LocalCRDTRegistryClient}
  alias IASCCustom.{HordeRegistry, HordeSupervisor}

  @process_registry :delta_crdt_process_registry

  def child_spec() do
    %{
      id: generate_name,
      start: {__MODULE__, :start_link, [generate_name]},
      restart: :transient,
    }
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, {name}, name: via_tuple_registry(name))
  end

  defp via_tuple_registry(name) do
    {:via, Registry, {@process_registry, name}}
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {HordeRegistry, name}}
  end

  @impl GenServer
  def init({name}) do
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap, sync_interval: 3)
    
    register(crdt, name)
    set_neighbours(crdt)

    {:ok, {name, crdt}}
  end

  @impl GenServer
  def handle_cast({:register, other_pids}, {name, crdt}) do
    pids_diff = List.delete(other_pids, crdt)
    :telemetry.execute(
      [:iasc_crdt, :neighbours, :setup],
      %{from: crdt, to: pids_diff, node: Node.self},
      %{}
    )
    DeltaCrdt.set_neighbours(crdt, pids_diff)

    {:noreply, {name, crdt}}
  end

  @impl GenServer
  def handle_cast({:put, key, value}, {name, crdt}) do
    DeltaCrdt.put(crdt, key, value)

    {:noreply, {name, crdt}}
  end

  @impl GenServer
  def handle_call(:get_map, _from, {name, crdt}) do
    {:reply, DeltaCrdt.to_map(crdt), {name, crdt}}
  end


  @impl GenServer
  def handle_call(:get_crdt, _from, {name, crdt}) do
    {:reply, crdt, {name, crdt}}
  end

  @impl GenServer
  def handle_cast({:update_crdt_neighbour, new_pid}, {name, crdt}) do
    crdt_state = :sys.get_state(crdt)
    current_neighbours = crdt_state.neighbours
    all_crdts = MapSet.put(current_neighbours, new_pid)
    GenServer.cast(self(), {:register, MapSet.to_list(all_crdts)})

    {:noreply, {name, crdt}}
  end
  
  # --- Client functions --- #

  def spawn_crdt() do
    HordeSupervisor.start_child(child_spec)
  end

  def put(pid, key, value) do
    GenServer.cast(pid, {:put, key, value})
  end

  def get_map(pid) do
    GenServer.call(pid, :get_map)
  end

  # ---- Private methods ---- #

  defp set_neighbours(crdt_pid) do
    Logger.info("#{inspect(all_crdt_clients_but_me)}")
    all_crdts = Enum.map(all_crdt_clients_but_me, fn crdt_client -> GenServer.call(crdt_client, :get_crdt) end)

    case all_crdts do
      []-> :ok # first crdt, dont do anything.
      crdts ->
        GenServer.cast(self(), {:register, crdts})
        IASC.LocalCRDTRegistryClient.notify_new_crdt(all_crdt_clients_but_me, crdt_pid)
    end  
  end

  defp all_crdt_clients_but_me do
    List.delete(IASC.LocalCRDTRegistryClient.get_all_crtds_clients_cluster, self)
  end

  defp register(crdt_pid, name) do
    register_local_name(name)
    register_crdt_process(crdt_pid, name)
    register_process_horde(name)
  end

  defp register_crdt_process(crdt_pid, name) do
    Horde.Registry.register(HordeRegistry, "crdt_#{name}", crdt_pid)
  end

  defp register_local_name(name) do
    GenServer.cast(LocalCRDTRegistryClient, {:add_crdt_pid, self()})
  end

  defp register_process_horde(name) do
    Horde.Registry.register(HordeRegistry, name, self())
  end

  defp generate_name do 
    random_string = Random.random_string(20)
    "deltacrdt-#{random_string}"
  end
end

# IASC.DeltaCRDT.spawn_crdt