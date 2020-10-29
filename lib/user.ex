defmodule FreshBex.User do
  use FreshBex.Resource, api_url_override: true, nested_resource_override: true, only: [:get]

  defstruct [
    :id,
    :identity_id,
    :first_name,
    :last_name,
    :email,
    :confirmed_at,
    :created_at,
    :unconfirmed_email,
    :setup_complete,
    :identity_origin,
    :identity_uuid,
    :language,
    profile: {},
    phone_numbers: [],
    addresses: [],
    profession: {},
    links: {},
    permissions: {},
    groups: [],
    subscription_statuses: {},
    integrations: {},
    business_memberships: [],
    roles: []
  ]

  def resource, do: "users"

  # This will be used instead of default because of the :custom_resource_nesting option
  def nested_resource(resource), do: resource.response

  # This will be used instead of default because of the :custom_url option
  def api_url(_), do: "https://api.freshbooks.com/auth/api/v1"

  @doc """
  Returns `%FreshBex.User{}` currently authenticated user
  """
  def me(options \\ []) do
    get([id: "me"] ++ options)
  end
end
