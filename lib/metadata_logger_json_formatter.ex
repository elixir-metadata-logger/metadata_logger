defmodule MetadataLoggerJsonFormatter do
  @moduledoc """
  Logger formatter to print message and metadata in a single-line json.

  ```json
  config :logger, :console,
    level: :debug,
    format: {MetadataLoggerJsonFormatter, :format},
    colors: [enabled: false],
    metadata: :all,
    truncate: :infinity,
    utc_log: true
  ```
  """
  def format(level, message, ts, metadata) do
    line =
      metadata
      |> build_line()
      |> scrub(level)
      |> Map.put(:timestamp, format_timestamp(ts))
      |> Map.put(:level, level)
      |> Map.put(:message, to_string(message))
      |> Jason.encode_to_iodata!()

    [line, "\n"]
  rescue
    _ -> "could not format: #{inspect({level, ts, message, metadata})}"
  end

  defp format_timestamp({{y, month, d}, {h, minutes, s, mil}}) do
    {:ok, dt} = NaiveDateTime.new(y, month, d, h, minutes, s, mil)
    NaiveDateTime.to_iso8601(dt)
  end

  defp build_line(metadata) do
    with m <- Enum.into(metadata, %{}),
         {app, m} <- Map.pop(m, :application),
         {module, m} <- Map.pop(m, :module),
         {function, m} <- Map.pop(m, :function),
         {file, m} <- Map.pop(m, :file),
         {line, m} <- Map.pop(m, :line),
         {pid, m} <- Map.pop(m, :pid) do
      %{metadata: m}
      |> put_val(:app, app)
      |> put_val(:module, module)
      |> put_val(:function, function)
      |> put_val(:file, file)
      |> put_val(:line, line)
      |> put_val(:pid, nil_or_inspect(pid))
    end
  end

  defp nil_or_inspect(nil), do: nil
  defp nil_or_inspect(val), do: inspect(val)

  def put_val(map, _key, nil), do: map
  def put_val(map, key, val), do: Map.put(map, key, val)

  defp scrub(map, _level) do
    map
    |> Map.delete(:func)
    |> Map.delete(:file)
    |> Map.delete(:line)
  end
end
