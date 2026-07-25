defmodule Exocomp.Node.RenewalScheduler do
  @moduledoc """
  Schedules certificate renewal from the active leaf certificate's expiry.

  Only one renewal runs at a time. Failures retain the current credentials and
  retry with bounded exponential backoff; successful renewal reloads expiry
  from the newly installed certificate.
  """

  use GenServer

  @day 86_400

  defstruct [
    :cert_path,
    :renew_fun,
    :timer,
    :now_fun,
    :expiry_fun,
    :renew_before_seconds,
    :max_backoff_seconds,
    :jitter_fun,
    backoff_seconds: 1,
    status: :scheduled,
    last_error: nil
  ]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))

  @spec status(GenServer.server()) :: map()
  def status(server), do: GenServer.call(server, :status)

  @impl true
  def init(opts) do
    state = %__MODULE__{
      cert_path: Keyword.fetch!(opts, :cert_path),
      renew_fun: Keyword.fetch!(opts, :renew_fun),
      now_fun: Keyword.get(opts, :now_fun, &DateTime.utc_now/0),
      expiry_fun: Keyword.get(opts, :expiry_fun, &__MODULE__.certificate_expiry/1),
      renew_before_seconds: Keyword.get(opts, :renew_before_seconds, 7 * @day),
      max_backoff_seconds: Keyword.get(opts, :max_backoff_seconds, 3_600),
      jitter_fun: Keyword.get(opts, :jitter_fun, &:rand.uniform/1)
    }

    {:ok, schedule(state)}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{status: state.status, last_error: state.last_error}, state}
  end

  @impl true
  def handle_info(:renew, state) do
    state = %{state | timer: nil, status: :renewing}

    result =
      try do
        state.renew_fun.()
      rescue
        exception -> {:error, {:exception, exception.__struct__}}
      catch
        kind, _reason -> {:error, {:exception, kind}}
      end

    case result do
      :ok ->
        {:noreply,
         state
         |> Map.merge(%{backoff_seconds: 1, status: :scheduled, last_error: nil})
         |> schedule()}

      {:ok, _result} ->
        {:noreply,
         state
         |> Map.merge(%{backoff_seconds: 1, status: :scheduled, last_error: nil})
         |> schedule()}

      {:error, reason} ->
        {:noreply, schedule_retry(state, reason)}

      _unexpected ->
        {:noreply, schedule_retry(state, :invalid_renewal_result)}
    end
  end

  @doc "Reads the first PEM certificate and returns its UTC expiration."
  @spec certificate_expiry(Path.t()) :: {:ok, DateTime.t()} | {:error, term()}
  def certificate_expiry(path) do
    with {:ok, pem} <- File.read(path),
         [{:Certificate, der, _} | _] <- :public_key.pem_decode(pem),
         certificate <- X509.Certificate.from_der!(der),
         {:Validity, _not_before, not_after} <- X509.Certificate.validity(certificate),
         {:ok, datetime} <- as_datetime(not_after) do
      {:ok, datetime}
    else
      _other -> {:error, :invalid_certificate}
    end
  rescue
    _exception -> {:error, :invalid_certificate}
  end

  defp schedule(state) do
    delay =
      case state.expiry_fun.(state.cert_path) do
        {:ok, expiry} ->
          seconds =
            DateTime.diff(expiry, state.now_fun.(), :second) - state.renew_before_seconds

          max(seconds, 0)

        {:error, _reason} ->
          0
      end

    timer = Process.send_after(self(), :renew, delay * 1_000)
    %{state | timer: timer}
  end

  defp jittered_backoff(state) do
    # Full jitter in [1, backoff] avoids synchronized fleet retries.
    max(1, state.jitter_fun.(max(1, state.backoff_seconds)))
  end

  defp schedule_retry(state, reason) do
    delay = jittered_backoff(state)
    timer = Process.send_after(self(), :renew, delay * 1_000)

    %{
      state
      | timer: timer,
        status: :retrying,
        last_error: reason,
        backoff_seconds: min(state.backoff_seconds * 2, state.max_backoff_seconds)
    }
  end

  defp as_datetime({:utcTime, chars}) do
    with <<year::binary-size(2), rest::binary-size(10)>> <-
           chars |> to_string() |> String.trim_trailing("Z"),
         numeric_year = String.to_integer(year),
         full_year = if(numeric_year >= 50, do: 1900 + numeric_year, else: 2000 + numeric_year) do
      build_utc_datetime(full_year, rest)
    end
  end

  defp as_datetime({:generalTime, chars}) do
    with <<year::binary-size(4), rest::binary-size(10)>> <-
           chars |> to_string() |> String.trim_trailing("Z") do
      build_utc_datetime(String.to_integer(year), rest)
    end
  end

  defp build_utc_datetime(
         year,
         <<month::binary-size(2), day::binary-size(2), hour::binary-size(2),
           minute::binary-size(2), second::binary-size(2)>>
       ) do
    with {:ok, naive} <-
           NaiveDateTime.new(
             year,
             String.to_integer(month),
             String.to_integer(day),
             String.to_integer(hour),
             String.to_integer(minute),
             String.to_integer(second)
           ),
         {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC") do
      {:ok, datetime}
    end
  end
end
