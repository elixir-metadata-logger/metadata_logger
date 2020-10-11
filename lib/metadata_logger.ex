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

      iex> MetadataLogger.format(
      ...>   :info,
      ...>   %{hello: :world},
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   function: "hello/1",
      ...>   file: "/my/file.ex",
      ...>   line: 11,
      ...>   foo: :bar
      ...> ) |> Jason.decode!()
      %{
        "level" => "info",
        "message" => %{"hello" => "world"},
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
    e ->
      %{
        level: "error",
        message: "could not format json message",
        logger_data: %{
          exception: inspect(e),
          level: inspect(level),
          ts: inspect(ts),
          message: inspect(message),
          metadata: inspect(metadata)
        }
      }
      |> Jason.encode!()
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
  - `:gl`
  - `:crash_reason`
  - `:initial_call`
  - `:registered_name`
  - `:domain`
  - `:ancestors`
  - `:callers`

  Followings metadata will be removed:

  - `:mfa`: see `:module` and `:funtion`
  - `:report_cb`

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

      iex> MetadataLogger.log_to_map(
      ...>   :info,
      ...>   %{hello: :world},
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   []
      ...> )
      %{
        level: :info,
        message: %{hello: :world},
        metadata: %{},
        timestamp: ~N[2019-11-22 12:23:45.000678]
      }

      iex> MetadataLogger.log_to_map(
      ...>   :info,
      ...>   [foo: 1, foo: 2],
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   []
      ...> )
      %{
        level: :info,
        message: %{foo: 2},
        metadata: %{},
        timestamp: ~N[2019-11-22 12:23:45.000678]
      }

      # use erl_level (available since Elixir 1.11)
      iex> MetadataLogger.log_to_map(
      ...>   :warn,
      ...>   [foo: 1, foo: 2],
      ...>   {{2019, 11, 22}, {12, 23, 45, 678}},
      ...>   [erl_level: :warning]
      ...> )
      %{
        level: :warning,
        message: %{foo: 2},
        metadata: %{},
        timestamp: ~N[2019-11-22 12:23:45.000678]
      }

  """
  @spec log_to_map(
          Logger.level(),
          Logger.message() | Logger.report(),
          Logger.Formatter.time(),
          keyword
        ) ::
          map()
  def log_to_map(level, message, ts, metadata) do
    m = Enum.into(metadata, %{})
    {level, m} = Map.pop(m, :erl_level, level)
    {time, m} = Map.pop(m, :time)

    with m <- Map.drop(m, [:error_logger, :mfa, :report_cb]),
         {app, m} <- Map.pop(m, :application),
         {module, m} <- Map.pop(m, :module),
         {function, m} <- Map.pop(m, :function),
         {file, m} <- Map.pop(m, :file),
         {line, m} <- Map.pop(m, :line),
         {pid, m} <- Map.pop(m, :pid),
         {gl, m} <- Map.pop(m, :gl),
         {ancestors, m} <- Map.pop(m, :ancestors),
         {callers, m} <- Map.pop(m, :callers),
         {crash_reason, m} <- Map.pop(m, :crash_reason),
         {initial_call, m} <- Map.pop(m, :initial_call),
         {domain, m} <- Map.pop(m, :domain),
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
      |> put_val(:domain, domain)
      |> put_val(:ancestors, nil_or_inspect_list(ancestors))
      |> put_val(:callers, nil_or_inspect_list(callers))
    end
    |> Map.put(:level, level)
    |> Map.put(:message, transform_message(message))
    |> Map.put(:timestamp, transform_timestamp(time, ts))
  end

  defp nil_or_inspect(nil), do: nil
  defp nil_or_inspect(val), do: inspect(val)

  defp nil_or_inspect_list(nil), do: nil
  defp nil_or_inspect_list(val), do: Enum.map(val, &inspect/1)

  defp put_val(map, _key, nil), do: map
  defp put_val(map, key, val), do: Map.put(map, key, val)

  defp transform_message(%_{} = m), do: to_string(m)
  defp transform_message(m) when is_map(m), do: m
  defp transform_message([{_k, _v} | _t] = m), do: Enum.into(m, %{})
  defp transform_message(m) when is_list(m), do: IO.iodata_to_binary(m)
  defp transform_message(m), do: to_string(m)

  defp transform_timestamp(nil, {{y, month, d}, {h, minutes, s, mil}}) do
    {:ok, dt} = NaiveDateTime.new(y, month, d, h, minutes, s, mil)
    dt
  end

  defp transform_timestamp(time_ms, _) do
    DateTime.from_unix!(time_ms, :microsecond)
  end

  defp scrub(map) do
    map
    |> Map.delete(:function)
    |> Map.delete(:file)
    |> Map.delete(:line)
  end
end
