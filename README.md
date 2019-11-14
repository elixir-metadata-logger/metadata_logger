# MetadataLogger

Logging with metadata.

## Installation

The package can be installed by adding `metadata_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:metadata_logger, "~> 0.2"}]
end
```

## Configuration

```elixir
config :logger, :console,
  level: :debug,
  format: {MetadataLogger, :format},
  colors: [enabled: false],
  metadata: :all,
  truncate: :infinity,
  utc_log: true
```

Full documentation can be found at [https://hexdocs.pm/metadata_logger](https://hexdocs.pm/metadata_logger).
