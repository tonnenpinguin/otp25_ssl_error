defmodule Test do
  @moduledoc """
  Documentation for `Test`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Test.hello()
      :world

  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(_opts) do
    send_tick()
    {:ok, nil}
  end

  defp send_tick(timeout \\ 100) do
    Process.send_after(self(), :tick, timeout)
  end

  @impl GenServer
  def handle_info(:tick, state) do
    Mint.HTTP.connect(:https, "0.0.0.0", 4001, transport_opts: build())
    send_tick(5000)
    {:noreply, state}
  end

  def build do
    certfile = Path.join("nerves-hub", "poser-cert.pem")
    keyfile = Path.join("nerves-hub", "poser-key.pem")

    signer =
      Path.join("nerves-hub", "poser-signer.cert")
      |> File.read!()

    [
      certfile: certfile,
      keyfile: keyfile,
      cacerts: build_cacerts(signer),
      log_level: :debug,
      versions: [:"tlsv1.3"]
    ]
  end

  def ca_certs() do
    Path.expand("../ssl/#{Mix.env()}/*", __DIR__)
    |> Path.wildcard()
    |> Enum.flat_map(&X509.from_pem(File.read!(&1)))
    |> Enum.map(&X509.Certificate.to_der/1)
  end

  defp build_cacerts(signer) do
    signer_der = pem_to_der(signer)

    [signer_der | ca_certs()]
  end

  def pem_to_der(nil), do: <<>>

  def pem_to_der(cert) do
    case X509.Certificate.from_pem(cert) do
      {:error, :not_found} -> <<>>
      {:ok, decoded} -> X509.Certificate.to_der(decoded)
    end
  end
end
