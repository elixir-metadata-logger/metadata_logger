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

  test "handles missing Logger metadata from Logger.bare_log/3" do
    keys_got =
      capture_log(fn -> Logger.bare_log(:info, "hello", hello: :world) end)
      |> Jason.decode!()
      |> Map.keys()
      |> MapSet.new()

    known_keys =
      [
        :app,
        :module,
        :function,
        :file,
        :line
        # :pid,
      ]
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    assert MapSet.new() == MapSet.intersection(keys_got, known_keys)
  end

  test "handles supported types in metadata" do
    cases = [
      atom: [:foo, "foo"],
      float: [0.12345678, 0.12345678],
      int: [1, 1],
      list: [[1, "1"], [1, "1"]],
      map: [%{"a" => 1, :b => "2"}, %{"a" => 1, "b" => "2"}],
      string: ["1", "1"]
    ]

    Enum.each(cases, fn {key, [val, expected]} ->
      assert {^key, %{"metadata" => %{"val" => ^expected}}} =
               {key, parsed_log(:info, "hello", val: val)}
    end)
  end

  test "handle unsupported types in metadata" do
    cases = [
      bitstring: <<1::3>>,
      fn: fn -> nil end,
      pid: self(),
      struct: %URI{},
      tuple: {}
    ]

    Enum.each(cases, fn {key, val} ->
      output = capture_log(fn -> Logger.log(:info, "hello", val: val) end)

      assert String.starts_with?(output, "could not format: "),
             "should not handle #{inspect(val)} (#{key})"
    end)
  end

  defp parsed_log(level, message, metadata) do
    captured = capture_log(fn -> Logger.log(level, message, metadata) end)
    Jason.decode!(captured)
  end
end
