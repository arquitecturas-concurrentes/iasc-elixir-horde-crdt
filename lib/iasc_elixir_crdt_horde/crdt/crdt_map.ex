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

    {:ok, {name, crdt}}
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
