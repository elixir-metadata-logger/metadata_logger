defmodule MetadataLoggerJsonFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :metadata_logger_json_formatter,
      version: "0.1.1-dev",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Logger formatter to print message and metadata in a single-line json",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/chulkilee/metadata_logger_json_formatter",
        "Changelog" =>
          "https://github.com/chulkilee/metadata_logger_json_formatter/blob/master/CHANGELOG.md"
      },
      maintainers: ["Chulki Lee"]
    ]
  end
end
