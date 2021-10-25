defmodule IASC.Telemetry.Instrumenter do
  require Logger

  def setup do
    events = [
      [:node, :event, :up],
      [:node, :event, :down],
      [:iasc_crdt, :registry, :up],
      [:iasc_crdt, :neighbours, :setup],
      [:iasc_crdt, :crdt, :new],
      [:delta_crdt, :sync, :done]
    ]
    :telemetry.attach_many("iasc-instrumenter", events, &handle_event/4, nil)
  end

  def handle_event([:node, :event, :up], measurements, metadata, _config) do
    Logger.debug("---- Node up: #{measurements.node_affected} ----")
  end

  def handle_event([:node, :event, :down], measurements, metadata, _config) do
    Logger.warn("---- Node down: #{measurements.node_affected} ----")
  end

  def handle_event([:iasc_crdt, :registry, :up], measurements, metadata, _config) do
    Logger.debug("New  Elixir.IASC.LocalCRDTRegistryClient: #{measurements.registry_name}")
    Logger.debug("Existing LocalCRDTRegistries on cluster: #{Enum.join(IASC.LocalCRDTRegistryClient.get_all_global_registries(), ", ")}")
  end

  def handle_event([:iasc_crdt, :crdt, :new], measurements, metadata, _config) do
    Logger.debug("New IASC.LocalCRDTRegistryClient pid #{measurements.pid} on node: #{measurements.node}")
  end

  def handle_event([:iasc_crdt, :neighbours, :setup], measurements, metadata, _config) do
    Logger.debug("DeltaCrdt.set_neighbours: #{inspect(measurements.from)} -> #{inspect(measurements.to)} in Node #{measurements.node}")
  end

  def handle_event(  [:delta_crdt, :sync, :done], measurements, metadata, _config) do
    Logger.debug("DeltaCrdt.sync done: #{inspect(measurements)} with metadata #{inspect(metadata)} in Node #{Node.self}")
  end
end