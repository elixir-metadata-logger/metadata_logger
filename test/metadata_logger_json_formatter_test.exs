defmodule MetadataLoggerJsonFormatterTest do
  use ExUnit.Case
  doctest MetadataLoggerJsonFormatter

  require Logger

  import ExUnit.CaptureLog

  setup do
    on_exit(fn ->
      :ok =
        Logger.configure_backend(
          :console,
          format: nil,
          device: :user,
          level: nil,
          metadata: :all,
          colors: [enabled: false]
        )
    end)

    Logger.configure_backend(:console,
      format: {MetadataLoggerJsonFormatter, :format},
      colors: [enabled: false],
      truncate: :infinity,
      metadata: :all
    )

    :ok
  end

  test "log in json" do
    assert %{
             "app" => nil,
             "module" => "Elixir.MetadataLoggerJsonFormatterTest",
             "pid" => _,
             "metadata" => %{"foo" => "bar", "list" => [1, 2, 3]},
             "timestamp" => _,
             "level" => "info",
             "message" => "hi"
           } = parsed_log(:info, "hi", foo: :bar, list: [1, 2, 3])
  end

  test "log metadata in current process" do
    try do
      Logger.metadata(foo: :bar)
      assert %{"metadata" => %{"foo" => "bar"}} = parsed_log(:info, "hi", [])
    after
      Logger.metadata(foo: nil)
    end
  end

  defp parsed_log(level, message, metadata) do
    captured = capture_log(fn -> Logger.log(level, message, metadata) end)
    Jason.decode!(captured)
  end
end
