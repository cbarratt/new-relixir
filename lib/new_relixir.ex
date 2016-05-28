defmodule NewRelixir do
  @moduledoc """
  Entry point for New Relixir OTP application.
  """

  use Application

  @doc """
  Application callback to start New Relixir.
  """
  @spec start(Application.app, Application.start_type) :: :ok | {:error, term}
  def start(_type \\ :normal, _args \\ []) do
    import Supervisor.Spec, warn: false

    children = [
      worker(:statman_server, [1000]),
      worker(:statman_aggregator, []),
    ]

    opts = [strategy: :one_for_one, name: NewRelixir.Supervisor]
    result = Supervisor.start_link(children, opts)

    :ok = :statman_server.add_subscriber(:statman_aggregator)

    if application_name && license_key do
      Application.put_env(:newrelic, :application_name, to_char_list(application_name))
      Application.put_env(:newrelic, :license_key, to_char_list(license_key))

      if (proxy) do
        Application.put_env(:newrelic, :proxy, to_char_list(proxy))
      end

      {:ok, _} = :newrelic_poller.start_link(&:newrelic_statman.poll/0)
    end

    result
  end

  @doc false
  @spec configured? :: boolean
  def configured? do
    application_name != nil && license_key != nil
  end

  defp license_key do
    Application.get_env(:new_relixir, :license_key)
  end

  defp application_name do
    Application.get_env(:new_relixir, :application_name)
  end

  defp proxy do
    Application.get_env(:new_relixir, :proxy)
  end
end
