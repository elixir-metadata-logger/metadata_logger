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
      |> Jason.encode!()

    line <> "\n"
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
      %{
        app: app,
        module: module,
        func: function,
        file: file,
        line: line,
        pid: inspect(pid),
        metadata: m
      }
    end
  end

  defp scrub(map, _level) do
    map
    |> Map.delete(:func)
    |> Map.delete(:file)
    |> Map.delete(:line)
  end
end
