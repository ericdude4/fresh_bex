defmodule FreshBex.Resource do
  @moduledoc """
  All FreshBooks requests require authorization headers. These can be set by deafult in your config file:

  ## Example Config
      config :fresh_bex,
        oauth_2_access_token: %OAuth2.AccessToken{},
        account_id: 12341234,
        redirect_uri: "REQUIRED"

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
      unless Keyword.get(opts, :resource_path_override) do
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
        nil -> [:get, :list, :create, :update, :delete]
        list -> list
      end

    # list/1 requires get/1
    get =
      if :get in inject || :list in inject do
        quote do
          @doc """
          Retrieve #{__MODULE__} by id. Accepts a keyword list of options.

          returns {%OAuth2.AccessToken{}, %#{__MODULE__}{}}

          ## Options
          * `:id` - The id of the resource you are trying to retrieve. Defaults to empty, giving same behaviour as list/1
          * `:get_parameters` - Map of query parameters that you want to include in the query.
          """
          def get(options \\ []) do
            resource_id = Keyword.get(options, :id)
            access_token = Keyword.get(options, :access_token)
            client = FreshBex.get_client(access_token)

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

            case OAuth2.Client.get(client, url) do
              {:ok, response = %OAuth2.Response{body: resource}} ->
                resource =
                  Jason.decode!(resource, keys: :atoms)
                  |> nested_resource()

                return_data =
                  if Map.has_key?(pagination_data(resource), :page) do
                    # This means the resource is a list of the resource, in an attribute named after the resource
                    resource_key = String.to_atom(resource())

                    if Application.get_env(:fresh_bex, :env, :prod) == :test do
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

                {client.token, return_data}

              {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                # run refresh then retry
                new_token = FreshBex.refresh_token(access_token)

                get(Keyword.put(options, :access_token, new_token))

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

            {access_token, resources} = get(options ++ [get_parameters: get_parameters])

            if Enum.count(resources) == per_page do
              get_recursive(
                options ++ [access_token: access_token],
                resources ++ collector,
                page + 1,
                per_page
              )
            else
              # all pages exhausted for resource. return collection
              {access_token, resources ++ collector}
            end
          end

          @doc """
          Retrieve list of #{__MODULE__} FreshBooks resource. Shares all options with get/1

          returns {%OAuth2.AccessToken{}, [%#{__MODULE__}{}]}

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

    create =
      if :create in inject do
        quote do
          @doc """
          Create new #{__MODULE__} resource. Parameters are not validated, but passed along in the request body. Please see FreshBooks API documentation for the appropriate body parameters for your resource.

          returns {%OAuth2.AccessToken{}, %#{__MODULE__}{}}

          ## Params
          * `properties` - Map of resource properties to create the resource with. This will be different for each resource based on the specification in Harvest API
          """
          def create(properties, options \\ []) do
            url = "#{api_url(options)}/#{resource_path()}"
            access_token = Keyword.get(options, :access_token)
            client = FreshBex.get_client(access_token)

            resource_name = resource() |> String.replace("ies", "y")

            body =
              case Jason.encode(Map.put(%{}, resource_name, properties)) do
                {:ok, body} ->
                  body

                {:error, %Jason.EncodeError{message: message}} ->
                  raise(
                    FreshBexError,
                    "Invalid :properties. Was not able to encode to JSON. #{message}"
                  )
              end

            case OAuth2.Client.post(client, url, body, [{"Content-Type", "application/json"}]) do
              {:ok, %OAuth2.Response{body: resource}} ->
                resource =
                  Jason.decode!(resource, keys: :atoms)
                  |> (fn map ->
                        # singluarize the resource() method so we know where to find the data
                        key =
                          if String.ends_with?(resource(), "ies") do
                            String.replace_suffix(resource(), "ies", "y")
                          else
                            String.replace_suffix(resource(), "s", "")
                          end
                          |> String.to_atom()

                        map[key]
                      end).()

                {client.token, struct!(__MODULE__, resource)}

              {:error, %OAuth2.Response{status_code: 422, body: body}} ->
                {:error, Jason.decode!(body)}

              {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                # run refresh then retry
                new_token = FreshBex.refresh_token(access_token)
                create(properties, Keyword.put(options, :access_token, new_token))

              {:error, %OAuth2.Error{reason: reason}} ->
                raise(FreshBexError, "Error: #{inspect(reason)}")
            end
          end
        end
      end

    update =
      if :update in inject do
        quote do
          @doc """
          Update given #{__MODULE__} resource. Parameters are not validated, but passed along in the request body. Please see FreshBooks API documentation for the appropriate body parameters for your resource.

          returns {%OAuth2.AccessToken{}, %#{__MODULE__}{}}

          ## Params
          * `id` - id of `#{__MODULE__}` resource being updated.
          * `changes` - Map of changes to be applied to the resource.
          """
          def update(id, changes, options \\ []) do
            url = "#{api_url(options)}/#{resource_path()}/#{id}"
            access_token = Keyword.get(options, :access_token)
            client = FreshBex.get_client(access_token)

            resource_name = resource() |> String.replace("ies", "y")

            body =
              case Jason.encode(Map.put(%{}, resource_name, changes)) do
                {:ok, body} ->
                  body

                {:error, %Jason.EncodeError{message: message}} ->
                  raise(
                    FreshBexError,
                    "Invalid :changes. Was not able to encode to JSON. #{message}"
                  )
              end

            case OAuth2.Client.put(client, url, body, [{"Content-Type", "application/json"}]) do
              {:ok, %OAuth2.Response{body: resource}} ->
                resource =
                  Jason.decode!(resource, keys: :atoms)
                  |> (fn map ->
                        # singluarize the resource() method so we know where to find the data
                        key =
                          if String.ends_with?(resource(), "ies") do
                            String.replace_suffix(resource(), "ies", "y")
                          else
                            String.replace_suffix(resource(), "s", "")
                          end
                          |> String.to_atom()

                        map[key]
                      end).()

                {client.token, struct!(__MODULE__, resource)}

              {:error, %OAuth2.Response{status_code: 422, body: body}} ->
                {:error, Jason.decode!(body)}

              {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                # run refresh then retry
                new_token = FreshBex.refresh_token(access_token)
                update(id, changes, Keyword.put(options, :access_token, new_token))

              {:error, %OAuth2.Error{reason: reason}} ->
                raise(FreshBexError, "Error: #{inspect(reason)}")
            end
          end
        end
      end

    delete =
      if :delete in inject do
        quote do
          @doc """
          Delete FreshBooks #{__MODULE__} with provided id.

          Will return `{%OAuth2.AccessToken{}, :ok}` on success, `{:error, 404}` if resource not found, or throw `FreshBexError` for implementation errors.

          ## Params
          * `id` - id of #{__MODULE__} resource to delete
          """
          def delete(id, options \\ []) do
            url = "#{api_url(options)}/#{resource_path()}/#{id}"
            access_token = Keyword.get(options, :access_token)
            client = FreshBex.get_client(access_token)

            case OAuth2.Client.delete(client, url) do
              {:ok, resp} ->
                case resp.status_code do
                  204 ->
                    {client.token, :ok}

                  404 ->
                    {:error, 404}

                  status_code when status_code > 399 ->
                    error = Jason.decode!(resp.body, keys: :atoms)
                    raise(FreshBexError, error)
                end

              {:error, %OAuth2.Response{status_code: 422, body: body}} ->
                {:error, Jason.decode!(body)}

              {:error, %OAuth2.Response{status_code: 401, body: body}} ->
                # run refresh then retry
                new_token = FreshBex.refresh_token(access_token)
                delete(id, Keyword.put(options, :access_token, new_token))

              {:error, %OAuth2.Error{reason: reason}} ->
                raise(FreshBexError, "Error: #{inspect(reason)}")
            end
          end
        end
      end

    [api_url, pagination_data, resource_path, nested_resource, get, list, create, update, delete]
  end
end
