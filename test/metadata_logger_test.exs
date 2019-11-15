defmodule MetadataLoggerTest do
  use ExUnit.Case
  doctest MetadataLogger

  @ts_tuple {{2019, 11, 22}, {12, 23, 45, 678}}
  @ts_iso8601 "2019-11-22T12:23:45.000678"

  test "uses to_string for struct message" do
    expected = %{
      "module" => "Elixir.MetadataLogger",
      "pid" => "#PID<" <> _ = inspect(self()),
      "metadata" => %{"foo" => "bar", "list" => [1, 2, 3]},
      "timestamp" => @ts_iso8601,
      "level" => "info",
      "message" => "https://elixir-lang.org"
    }

    got =
      parse_formatted(:info, URI.parse("https://elixir-lang.org"), @ts_tuple,
        module: MetadataLogger,
        function: "hello/1",
        file: "/my/file.ex",
        line: 11,
        pid: self(),
        foo: :bar,
        list: [1, 2, 3]
      )

    assert expected == got
  end

  test "cannot handle a map with non-encodable" do
    got =
      parse_formatted(:info, %{uri: URI.parse("https://elixir-lang.org")}, @ts_tuple,
        module: MetadataLogger,
        function: "hello/1",
        file: "/my/file.ex",
        line: 11,
        pid: self(),
        foo: :bar,
        list: [1, 2, 3]
      )
      |> Map.fetch!("message")

    assert String.starts_with?(got, "could not format json message")
  end

  test "moves known metadata into top level" do
    expected = %{
      "module" => "Elixir.MetadataLogger",
      "pid" => "#PID<" <> _ = inspect(self()),
      "gl" => "#PID<" <> _ = inspect(self()),
      "ancestors" => ["#PID<" <> _ = inspect(self())],
      "callers" => ["#PID<" <> _ = inspect(self())],
      "domain" => ["elixir"],
      "metadata" => %{"foo" => "bar", "list" => [1, 2, 3]},
      "timestamp" => @ts_iso8601,
      "level" => "info",
      "message" => "hi"
    }

    got =
      parse_formatted(:info, "hi", @ts_tuple,
        module: MetadataLogger,
        function: "hello/1",
        file: "/my/file.ex",
        line: 11,
        pid: self(),
        gl: self(),
        foo: :bar,
        list: [1, 2, 3],
        domain: [:elixir],
        ancestors: [self()],
        callers: [self()]
      )

    assert expected == got
  end

  test "does not include nil value for known metadata" do
    expected = %{
      "metadata" => %{"nil_val" => nil, "empty_map" => %{}, "empty_list" => []},
      "timestamp" => @ts_iso8601,
      "level" => "info",
      "message" => "hi"
    }

    got = parse_formatted(:info, "hi", @ts_tuple, nil_val: nil, empty_map: %{}, empty_list: [])

    assert expected == got
  end

  test "handles supported types in metadata" do
    expected = %{
      "metadata" => %{
        "atom" => "foo",
        "float" => 0.12345678,
        "int" => 1,
        "list" => [1, "1"],
        "map" => %{"a" => 1, "b" => "2"},
        "string" => "1"
      },
      "timestamp" => @ts_iso8601,
      "level" => "info",
      "message" => "hi"
    }

    got =
      parse_formatted(:info, "hi", @ts_tuple,
        atom: :foo,
        float: 0.12345678,
        int: 1,
        list: [1, "1"],
        map: %{"a" => 1, :b => "2"},
        string: "1"
      )

    assert expected == got
  end

  test "handle unsupported types in metadata" do
    cases = [
      bitstring: <<1::3>>,
      fn: fn -> nil end,
      pid: self(),
      struct: %URI{},
      tuple: {}
    ]

    Enum.each(cases, fn {_key, val} ->
      output = parse_formatted(:info, "hi", @ts_tuple, val: val)
      expected_metadata = inspect(val: val)
      expected_ts = inspect(@ts_tuple)

      assert %{
               "level" => "error",
               "message" => "could not format json message",
               "logger_data" => %{
                 "level" => ":info",
                 "message" => "\"hi\"",
                 "ts" => ^expected_ts,
                 "exception" => exception,
                 "metadata" => ^expected_metadata
               }
             } = output

      assert String.starts_with?(exception, "%Protocol.UndefinedError{")
    end)
  end

  test "handles erlang error logger metadata" do
    expected = %{
      "crash_reason" => "{:foo, []}",
      "initial_call" => "{:hello, :world, 1}",
      "registered_name" => ":me",
      "metadata" => %{},
      "timestamp" => @ts_iso8601,
      "level" => "info",
      "message" => "hi"
    }

    got =
      parse_formatted(:info, "hi", @ts_tuple,
        crash_reason: {:foo, []},
        initial_call: {:hello, :world, 1},
        report_cb: & &1,
        mfa: {Foo, :bar, 1},
        registered_name: :me,
        error_logger: %{
          report_cb: & &1,
          tag: :info_report,
          type: :std_info
        }
      )

    assert expected == got
  end

  defp formatted(level, message, ts, metadata) do
    output_iodata = MetadataLogger.format(level, message, ts, metadata)

    IO.iodata_to_binary(output_iodata)
  end

  defp parse_formatted(level, message, ts, metadata) do
    output = formatted(level, message, ts, metadata)

    Jason.decode!(output)
  end
end
