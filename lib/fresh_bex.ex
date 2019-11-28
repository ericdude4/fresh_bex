defmodule FreshBex do
  @moduledoc """
  Documentation for FreshBex.

  You shouldn't need to use any of these functions directly.
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

        token ->
          IO.inspect(token)
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
end
