defmodule FreshBex.TimeEntry do
  use FreshBex.Resource,
    api_url_override: true,
    pagination_data_override: true,
    nested_resource_override: true

  defstruct [
    :id,
    :note,
    :duration,
    :billable,
    :billed,
    :created_at,
    :duration_rounded_to_nearest_minute,
    :project_id,
    :client_id,
    :is_logged,
    :identity_id,
    :pending_client,
    :pending_project,
    :internal,
    :pending_task,
    :retainer_id,
    :task_id,
    :service_id,
    :started_at,
    :active,
    :timer
  ]

  def resource, do: "time_entries"

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

    "https://api.freshbooks.com/timetracking/business/#{business_id}"
  end
end
