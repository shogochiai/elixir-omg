defmodule OMG.API.MixProject do
  use Mix.Project

  def project do
    [
      app: :omg_api,
      version: OMG.Umbrella.MixProject.umbrella_version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      env: [
        deposit_finality_margin: 10,
        submission_finality_margin: 20,
        ethereum_status_check_interval_ms: 6_000,
        child_block_minimal_enquque_gap: 1
      ],
      extra_applications: [:sentry, :logger],
      mod: {OMG.API.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "test/support"]

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:propcheck, "~> 1.1", only: [:dev, :test]},
      {:phoenix_pubsub, "~> 1.0"},
      {:ex_rlp, "~> 0.2.1"},
      {:blockchain, "~> 0.1.6"},
      {:merkle_tree,
       git: "https://github.com/omisego/merkle_tree.git", branch: "feature/omg-184-add-option-to-not-hash-leaves"},
      {:libsecp256k1, "~> 0.1.4", compile: "${HOME}/.mix/rebar compile", override: true},
      #
      {:omg_db, in_umbrella: true},
      {:omg_eth, in_umbrella: true},
      {:omg_rpc, in_umbrella: true},
      {:sentry, "~> 6.2.0"}
    ]
  end
end
