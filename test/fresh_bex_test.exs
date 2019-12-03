defmodule FreshBexTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest FreshBex

  setup_all do
    HTTPoison.start()
  end

  test "gets authenticated user" do
    use_cassette "user.me" do
      assert %FreshBex.User{} = FreshBex.User.me()
    end
  end

  test "gets authenticated user's clients" do
    use_cassette "clients.list" do
      assert [%FreshBex.Client{} | _] = FreshBex.Client.list()
    end
  end

  test "gets authenticated user's clients recursing pagination" do
    use_cassette "clients.list.recurse" do
      assert [%FreshBex.Client{} | _] = FreshBex.Client.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's projects" do
    use_cassette "projects.list.recurse" do
      assert [%FreshBex.Project{} | _] = FreshBex.Project.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's tasks" do
    use_cassette "tasks.list.recurse" do
      assert [%FreshBex.Task{} | _] = FreshBex.Task.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's time entries" do
    use_cassette "time_entries.list.recurse" do
      assert [%FreshBex.TimeEntry{} | _] = FreshBex.TimeEntry.list(recurse_pages: true)
    end
  end

  test "create time entry" do
    use_cassette "time_entry.create" do
      properties = %{
        is_logged: true,
        duration: 7200,
        note: "test",
        started_at: "2019-12-01T20:00:00.000Z",
        client_id: 201_781,
        project_id: 3_624_248
      }

      assert %FreshBex.TimeEntry{} = FreshBex.TimeEntry.create(properties)
    end
  end

  test "update time entry" do
    use_cassette "time_entry.update" do
      time_entry = %FreshBex.TimeEntry{
        active: true,
        billable: true,
        billed: false,
        client_id: 201_781,
        created_at: "2019-12-02T22:23:36Z",
        duration: 4000,
        duration_rounded_to_nearest_minute: 4000,
        id: 60_626_711,
        identity_id: 2_804_980,
        internal: false,
        is_logged: true,
        note: "test",
        pending_client: nil,
        pending_project: nil,
        pending_task: nil,
        project_id: 3_624_248,
        retainer_id: nil,
        service_id: nil,
        started_at: "2019-12-01T20:00:00Z",
        task_id: nil,
        timer: nil
      }

      changes = %{
        is_logged: true,
        duration: 5000,
        note: "test",
        started_at: "2019-12-01T20:00:00.000Z",
        client_id: 201_781,
        project_id: 3_624_248
      }

      assert %FreshBex.TimeEntry{duration: 5000} = FreshBex.TimeEntry.update(time_entry, changes)
    end
  end

  test "delete time entry" do
    use_cassette "time_entry.delete" do
      assert :ok = FreshBex.TimeEntry.delete(60_626_711)
    end
  end
end
