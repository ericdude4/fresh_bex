defmodule FreshBex.Client do
  use FreshBex.Resource, resource_path_override: true

  defstruct [
    :id,
    :allow_late_notifications,
    :s_code,
    :fax,
    :last_activity,
    :num_logins,
    :vat_number,
    :pref_email,
    :direct_link_token,
    :s_province,
    :vat_name,
    :lname,
    :s_city,
    :s_street2,
    :statement_token,
    :note,
    :mob_phone,
    :last_login,
    :home_phone,
    :company_industry,
    :subdomain,
    :email,
    :username,
    :updated,
    :p_province,
    :p_city,
    :bus_phone,
    :allow_late_fees,
    :p_street,
    :company_size,
    :accounting_systemid,
    :p_code,
    :signup_date,
    :language,
    :level,
    :notified,
    :userid,
    :p_street2,
    :pref_gmail,
    :vis_state,
    :s_country,
    :s_street,
    :fname,
    :organization,
    :p_country,
    :currency_code,
    :role,
    :retainer_id,
    :has_retainer
  ]

  def resource, do: "clients"

  def resource_path, do: "users/clients"
end
