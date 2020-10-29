defmodule FreshBex do
  @moduledoc """
  Documentation for FreshBex.
  """

  @doc """
  Build and return an %OAuth2.Client{} struct with provided %OAuth2.AccessToken{} parameter
  """
  def get_client(access_token \\ nil) do
    access_token =
      case access_token do
        nil ->
          case Application.fetch_env!(
                 :fresh_bex,
                 :oauth_2_access_token
               ) do
            nil ->
              raise(FreshBexError, "no access token provided")

            %OAuth2.AccessToken{} = access_token ->
              access_token
          end

        %OAuth2.AccessToken{} = access_token ->
          access_token

        token = %{
          access_token: _,
          token_type: _,
          refresh_token: _
        } ->
          struct!(OAuth2.AccessToken, token)

        %{
          "access_token" => access_token,
          "token_type" => token_type,
          "refresh_token" => refresh_token,
          "created_at" => created_at,
          "expires_in" => expires_in
        } ->
          # This is the format that the new tokens come from fresh books
          %OAuth2.AccessToken{
            access_token: access_token,
            token_type: token_type,
            access_token: access_token,
            refresh_token: refresh_token,
            expires_at: created_at + expires_in
          }

        %{
          "access_token" => access_token,
          "token_type" => token_type,
          "refresh_token" => refresh_token,
          "expires_at" => expires_at
        } ->
          # this is the format which the tokens are stored in the database
          %OAuth2.AccessToken{
            access_token: access_token,
            token_type: token_type,
            refresh_token: refresh_token,
            expires_at: expires_at
          }

        _token ->
          raise(FreshBexError, "invalid access token provided")
      end

    %OAuth2.Client{
      authorize_url: "/auth/oauth/token",
      token_url: "/auth/oauth/token",
      client_id: Application.fetch_env!(:fresh_bex, :client_id),
      client_secret: Application.fetch_env!(:fresh_bex, :client_secret),
      redirect_uri: Application.fetch_env!(:fresh_bex, :redirect_uri),
      site: "https://api.freshbooks.com",
      token: access_token
    }
  end

  @doc """
  Exchanges an OAuth code for an access token.

  returns `%OAuth2.AccessToken{}`
  """
  def authorize(code) do
    client =
      OAuth2.Client.new(
        token_url: "/auth/oauth/token",
        client_id: Application.fetch_env!(:fresh_bex, :client_id),
        client_secret: Application.fetch_env!(:fresh_bex, :client_secret),
        redirect_uri: Application.fetch_env!(:fresh_bex, :redirect_uri),
        site: "https://api.freshbooks.com"
      )
      |> OAuth2.Client.put_serializer("application/json", Jason)
      |> OAuth2.Client.get_token!(code: code)

    client.token
  end

  @doc """
  Refresh an access token, and return a new access token.

  returns `%OAuth2.Client{}`
  """
  def refresh_token(access_token) do
    refresh_token = access_token["refresh_token"]

    params = %{
      "refresh_token" => refresh_token,
      "grant_type" => "refresh_token",
      "client_secret" => Application.fetch_env!(:fresh_bex, :client_secret),
      "client_id" => Application.fetch_env!(:fresh_bex, :client_id),
      "redirect_uri" => Application.fetch_env!(:fresh_bex, :redirect_uri)
    }

    case HTTPoison.post("https://api.freshbooks.com/auth/oauth/token", Jason.encode!(params), [
           {"Api-Version", "alpha"},
           {"Content-Type", "application/json"}
         ]) do
      {:ok, response} ->
        case Jason.decode(response.body) do
          {:ok, token = %{"access_token" => _access_token}} ->
            token

          {:ok, error = %{"error" => _error_reason}} ->
            raise(FreshBexError, "Unable to refresh token: #{inspect(error)}")

          {:error, error} ->
            raise(FreshBexError, "Error: #{inspect(error)}")
        end

      {:error, error} ->
        raise(FreshBexError, "Error: #{inspect(error)}")
    end
  end
end
