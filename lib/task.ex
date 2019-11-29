defmodule FreshBex.Task do
  use FreshBex.Resource, overrides_resource_path: true

  defstruct [
    :id,
    :updated,
    :description,
    :vis_state,
    :rate,
    :taskid,
    :billable,
    :tname,
    :tdesc,
    :name,
    :tax1,
    :tax2
  ]

  def resource, do: "tasks"

  def resource_path, do: "projects/tasks"
end
