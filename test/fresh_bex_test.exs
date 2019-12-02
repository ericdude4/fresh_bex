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
end
