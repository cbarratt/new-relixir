defmodule NewRelixir.Plug.PhoenixRouter do
  @moduledoc """
  A plug that instruments Phoenix routers and records their response times in New Relic.

  Inside an instrumented router's actions, `conn` can be used for further instrumentation with
  `NewRelixir.Plug.Instrumentation` and `NewRelixir.Plug.Repo`.

  ```
  defmodule MyApp.Router do
    use Phoenix.Web :router
    plug NewRelixir.Plug.PhoenixRouter

    def index(conn, _params) do
      # `conn` is setup for instrumentation
    end
  end
  ```
  """

  @behaviour Elixir.Plug
  import Elixir.Phoenix.Controller
  import Elixir.Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _config) do
    if NewRelixir.configured? do
      module = conn |> router_module |> inspect
      forward_plug = conn |> plugs |> first_plug |> inspect
      transaction_name = "/#{module}##{forward_plug}"

      conn
      |> put_private(:new_relixir_transaction, NewRelixir.Transaction.start(transaction_name))
      |> register_before_send(fn conn ->
        NewRelixir.Transaction.finish(Map.get(conn.private, :new_relixir_transaction))
        conn
      end)
    else
      conn
    end
  end

  def first_plug({[], plugs}), do: plugs |> Map.keys |> List.first
  def first_plug(_), do: ""

  def plugs(conn), do: conn.private[router_module(conn)]
end
