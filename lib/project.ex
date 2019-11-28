defmodule FreshBex.Project do
  use FreshBex.Resource,
    api_url_override: true,
    pagination_data_override: true,
    nested_resource_override: true

  defstruct [
    :id,
    :due_date,
    :links,
    :fixed_price,
    :group,
    :description,
    :complete,
    :title,
    :project_type,
    :updated_at,
    :sample,
    :services,
    :rate,
    :internal,
    :client_id,
    :active,
    :created_at,
    :logged_duration,
    :billing_method,
    :billed_amount,
    :billed_status,
    :budget,
    :group_id,
    :logged_duration_rounded_to_nearest_minute,
    :retainer_id
  ]

  def resource, do: "projects"

  def pagination_data(resource), do: Map.get(resource, :meta)

  def nested_resource(resource), do: resource

  def api_url(opts) do
    business_id =
      case Keyword.get(opts, :business_id) do
        nil ->
          case Application.fetch_env!(:fresh_bex, :business_id) do
            nil ->
              raise(FreshBexError, "no business_id option provided")

            business_id ->
              business_id
          end

        business_id ->
          business_id
      end

    "https://api.freshbooks.com/projects/business/#{business_id}"
  end
end
