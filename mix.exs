defmodule MetadataLogger.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :metadata_logger,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Logging with metadata",
      package: package(),

      # ex_doc
      docs: docs()
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
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-metadata-logger/metadata_logger",
        "Changelog" =>
          "https://github.com/elixir-metadata-logger/metadata_logger/blob/master/CHANGELOG.md"
      },
      maintainers: ["Chulki Lee"]
    ]
  end

  defp docs do
    [
      name: "MetadataLogger",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/metadata_logger",
      source_url: "https://github.com/elixir-metadata-logger/metadata_logger"
    ]
  end
end
