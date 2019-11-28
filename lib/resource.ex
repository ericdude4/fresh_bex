defmodule FreshBex.Resource do
  @moduledoc """
  All FreshBooks requests require authorization headers. These can be set by deafult in your config file:

  ## Example Config
      config :fresh_bex,
        oauth_2_access_token: %OAuth2.AccessToken{},
        account_id: 12341234

  The authorization headers can be customized for each request using the following options provided as a keyword list in each resource function:

  ## Shared Authorization Options
  * `:access_token` - Required. Accepts `%OAuth2.AccessToken{}` struct. Can be set in config
  * `:account_id` - Required. `string`. Can be set in config
  * `:business_id` - Required for FreshBex.Project methods. `string`. Can be set in config
  """

  defmacro __using__(opts) do
    api_url =
      unless Keyword.get(opts, :api_url_override) do
        quote do
          def api_url(options \\ []) do
            account_id =
              case Keyword.get(options, :account_id) do
                nil ->
                  case Application.fetch_env!(:fresh_bex, :account_id) do
                    nil ->
                      raise(FreshBexError, "no account_id option provided")

                    account_id ->
                      account_id
                  end

                account_id ->
                  account_id
              end

            "https://api.freshbooks.com/accounting/account/#{account_id}"
          end
        end
      end

    pagination_data =
      unless Keyword.get(opts, :pagination_data_override) do
        quote do
          def pagination_data(resource), do: resource
        end
      end

    resource_path =
      unless Keyword.get(opts, :overrides_resource_path) do
        quote do
          # Default to simply return the resource name as the resource path
          def resource_path() do
            resource()
          end
        end
      end

    nested_resource =
      unless Keyword.get(opts, :nested_resource_override) do
        quote do
          def nested_resource(resource), do: resource.response.result
        end
      end

    inject =
      case Keyword.get(opts, :only) do
        nil -> [:get, :list]
        list -> list
      end

    # list/1 requires get/1
    get =
      if :get in inject || :list in inject do
        quote do
          @doc """
          Retrieve #{__MODULE__} by id. Accepts a keyword list of options.

          ## Options
          * `:id` - The id of the resource you are trying to retrieve. Defaults to empty, giving same behaviour as list/1
          * `:get_parameters` - Map of query parameters that you want to include in the query.
          """
          def get(options \\ []) do
            resource_id = Keyword.get(options, :id)

            url =
              "#{api_url(options)}/#{resource_path()}"
              |> (fn url ->
                    # Avoid the trailing "/" character when not necessary
                    if resource_id do
                      "#{url}/#{resource_id}"
                    else
                      url
                    end
                  end).()
              |> (fn url ->
                    case Keyword.get(options, :get_parameters) do
                      nil ->
                        url

                      get_parameters ->
                        url <> "?" <> URI.encode_query(get_parameters)
                    end
                  end).()

            case OAuth2.Client.get(
                   FreshBex.get_client(Keyword.get(options, :access_token)),
                   url
                 ) do
              {:ok, %OAuth2.Response{body: resource}} ->
                resource =
                  Jason.decode!(resource, keys: :atoms)
                  |> nested_resource()

                if Map.has_key?(pagination_data(resource), :page) do
                  # This means the resource is a list of the resource, in an attribute named after the resource
                  resource_key = String.to_atom(resource())

                  if Mix.env() == :test do
                    # lets learn about new keys that freshbooks adds to their data objects without crashing in prod
                    resource[resource_key]
                    |> Enum.map(&struct!(__MODULE__, &1))
                  else
                    resource[resource_key]
                    |> Enum.map(&struct(__MODULE__, &1))
                  end
                else
                  struct!(__MODULE__, resource)
                end

              {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                # run refresh then retry
                case OAuth2.Client.refresh_token(
                       FreshBex.get_client(Keyword.get(options, :access_token))
                     ) do
                  {:ok, %OAuth2.Client{} = client} ->
                    get(options ++ [access_token: client.token])

                  {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                    raise(FreshBexError, "Invalid refresh token")

                  {:error, %OAuth2.Error{reason: reason}} ->
                    raise(FreshBexError, "Error: #{inspect(reason)}")
                end

              {:error, %OAuth2.Error{reason: reason}} ->
                raise(FreshBexError, "Error: #{inspect(reason)}")
            end
          end
        end
      end

    list =
      if :list in inject do
        quote do
          defp get_recursive(
                 options \\ [],
                 collector \\ [],
                 page \\ 1,
                 per_page \\ 100
               ) do
            get_parameters =
              case Keyword.get(options, :get_parameters) do
                nil ->
                  %{page: page, per_page: per_page}

                get_parameters ->
                  Map.merge(get_parameters, %{page: page, per_page: per_page})
              end

            resources = get(options ++ [get_parameters: get_parameters])

            if Enum.count(resources) == per_page do
              get_recursive(options, resources ++ collector, page + 1, per_page)
            else
              # all pages exhausted for resource. return collection
              resources ++ collector
            end
          end

          @doc """
          Retrieve list of #{__MODULE__} FreshBooks resource. Shares all options with get/1

          ## Options
          * `:page` - The page number to use in pagination. Default 1
          * `:per_page` - The number of records to return per page. Can range between 1 and 100. Default 100
          * `:recurse_pages` - Recursively follow each next page and return all records.
          * `:get_parameters` - Map of query parameters that you want to include in the query.
          """
          def list(options \\ []) do
            page = Keyword.get(options, :page, 1)
            per_page = Keyword.get(options, :per_page, 100)

            if Keyword.get(options, :recurse_pages) do
              get_recursive(options, [], page, per_page)
            else
              get(options ++ [get_parameters: %{page: page, per_page: per_page}])
            end
          end
        end
      end

    [api_url, pagination_data, resource_path, nested_resource, get, list]
  end
end
