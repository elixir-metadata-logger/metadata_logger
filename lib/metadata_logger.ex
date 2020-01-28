defmodule MetadataLogger do
  @moduledoc """
  Logging with metadata.

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
  """

  @doc """
  Formatter function to print message and metadata in a single-line json.

  Make sure all metadata except known metadata encodable by `Jason.encode_to_iodata!/2`.
  See `log_to_map/4` for transformation on known metadata.

  It removes `:function`, `:file`, and `:line` from the log.

  ## Examples

      iex> MetadataLogger.format(
      ...>   :info,
      ...>   ["hello", " ", "world"],
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   function: "hello/1",
      ...>   file: "/my/file.ex",
      ...>   line: 11,
      ...>   foo: :bar
      ...> ) |> Jason.decode!()
      %{
        "level" => "info",
        "message" => "hello world",
        "metadata" => %{"foo" => "bar"},
        "timestamp" => "2019-11-22T12:23:45.000678"
      }

  """
  @spec format(Logger.level(), Logger.message(), Logger.Formatter.time(), keyword) ::
          IO.chardata()
  def format(level, message, ts, metadata) do
    map = log_to_map(level, message, ts, metadata)

    [
      map
      |> scrub()
      |> Jason.encode_to_iodata!(map),
      "\n"
    ]
  rescue
    e -> "could not format: #{inspect(e)} - #{inspect({level, ts, message, metadata})}"
  end

  @doc """
  Get a map from log formatter arguments.

  It converts `t:Logger.Formatter.time/0` into `NaiveDateTime` so it is recommended to configure logger to use UTC by setting `:utc_log` to `true`.

  It converts metadata keyword into map using `Enum.into/2` therefore duplicated keys will be removed.

  It moves following known metadata to the top level. See [Logger Metadata](https://hexdocs.pm/logger/Logger.html#module-metadata) for details.

  - `:application`
  - `:module`
  - `:function`
  - `:file`
  - `:line`
  - `:pid`
  - `:crash_reason`
  - `:initial_call`
  - `:registered_name`

  ## Examples

      iex> MetadataLogger.log_to_map(
      ...>   :info,
      ...>   ["hello", " ", "world"],
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   foo: :bar
      ...> )
      %{
        level: :info,
        message: "hello world",
        metadata: %{foo: :bar},
        timestamp: ~N[2019-11-22 12:23:45.000678]
      }

  """
  @spec log_to_map(Logger.level(), Logger.message(), Logger.Formatter.time(), keyword) ::
          map()
  def log_to_map(level, message, ts, metadata) do
    with m <- Enum.into(metadata, %{}),
         m <- Map.drop(m, [:mfa, :report_cb]),
         {app, m} <- Map.pop(m, :application),
         {module, m} <- Map.pop(m, :module),
         {function, m} <- Map.pop(m, :function),
         {file, m} <- Map.pop(m, :file),
         {line, m} <- Map.pop(m, :line),
         {pid, m} <- Map.pop(m, :pid),
         {gl, m} <- Map.pop(m, :gl),
         {crash_reason, m} <- Map.pop(m, :crash_reason),
         {initial_call, m} <- Map.pop(m, :initial_call),
         {registered_name, m} <- Map.pop(m, :registered_name) do
      %{metadata: m}
      |> put_val(:app, app)
      |> put_val(:module, module)
      |> put_val(:function, function)
      |> put_val(:file, file)
      |> put_val(:line, line)
      |> put_val(:pid, nil_or_inspect(pid))
      |> put_val(:gl, nil_or_inspect(gl))
      |> put_val(:crash_reason, nil_or_inspect(crash_reason))
      |> put_val(:initial_call, nil_or_inspect(initial_call))
      |> put_val(:registered_name, nil_or_inspect(registered_name))
    end
    |> Map.put(:timestamp, transform_timestamp(ts))
    |> Map.put(:level, level)
    |> Map.put(:message, to_string(message))
  end

  defp nil_or_inspect(nil), do: nil
  defp nil_or_inspect(val), do: inspect(val)

  defp put_val(map, _key, nil), do: map
  defp put_val(map, key, val), do: Map.put(map, key, val)

  defp transform_timestamp({{y, month, d}, {h, minutes, s, mil}}) do
    {:ok, dt} = NaiveDateTime.new(y, month, d, h, minutes, s, mil)
    dt
  end

  defp scrub(map) do
    map
    |> Map.delete(:function)
    |> Map.delete(:file)
    |> Map.delete(:line)
  end
end
