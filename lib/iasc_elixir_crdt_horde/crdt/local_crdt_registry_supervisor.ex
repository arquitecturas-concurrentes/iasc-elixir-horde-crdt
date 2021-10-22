defmodule IASC.LocalCRDTRegistry.Supervisor do
  use Supervisor
 
  def start_link(init_arg) do
   Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: :delta_crdt_process_registry },
      {IASC.LocalCRDTRegistryClient, []}
    ]
  
    Supervisor.init(children, strategy: :one_for_one)
  end
 end