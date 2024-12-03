defmodule JSONPathEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpath_ex,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "JSONPathEx",
      description: description(),
      source_url: "https://github.com/b-erdem/jsonpath_ex",
      homepage_url: "https://hex.pm/packages/jsonpath_ex",
      docs: &docs/0
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "A powerful Elixir library for parsing and evaluating JSONPath expressions."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "JSONPathEx",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Baris Erdem baris@erdem.dev"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/b-erdem/jsonpath_ex",
        "Hex" => "https://hex.pm/packages/jsonpath_ex"
      }
    ]
  end
end
