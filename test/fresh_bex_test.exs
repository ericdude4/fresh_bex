defmodule FreshBexTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest FreshBex

  setup_all do
    HTTPoison.start()
  end

  test "gets authenticated user" do
    use_cassette "user.me" do
      assert {%OAuth2.AccessToken{}, %FreshBex.User{}} = FreshBex.User.me()
    end
  end

  test "gets authenticated user's clients" do
    use_cassette "clients.list" do
      assert {%OAuth2.AccessToken{}, [%FreshBex.Client{} | _]} = FreshBex.Client.list()
    end
  end

  test "gets authenticated user's clients recursing pagination" do
    use_cassette "clients.list.recurse" do
      assert {%OAuth2.AccessToken{}, [%FreshBex.Client{} | _]} =
               FreshBex.Client.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's projects" do
    use_cassette "projects.list.recurse" do
      assert {%OAuth2.AccessToken{}, [%FreshBex.Project{} | _]} =
               FreshBex.Project.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's tasks" do
    use_cassette "tasks.list.recurse" do
      assert {%OAuth2.AccessToken{}, [%FreshBex.Task{} | _]} =
               FreshBex.Task.list(recurse_pages: true)
    end
  end

  test "gets authenticated user's time entries" do
    use_cassette "time_entries.list.recurse" do
      assert {%OAuth2.AccessToken{}, [%FreshBex.TimeEntry{} | _]} =
               FreshBex.TimeEntry.list(recurse_pages: true)
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

      assert {%OAuth2.AccessToken{}, %FreshBex.TimeEntry{}} =
               FreshBex.TimeEntry.create(properties)
    end
  end

  test "update time entry" do
    use_cassette "time_entry.update" do
      changes = %{
        is_logged: true,
        duration: 5000,
        note: "test",
        started_at: "2019-12-01T20:00:00.000Z",
        client_id: 201_781,
        project_id: 3_624_248
      }

      assert {%OAuth2.AccessToken{}, %FreshBex.TimeEntry{duration: 5000}} =
               FreshBex.TimeEntry.update(60_626_711, changes)
    end
  end

  test "delete time entry" do
    use_cassette "time_entry.delete" do
      assert {%OAuth2.AccessToken{}, :ok} = FreshBex.TimeEntry.delete(60_626_711)
    end
  end

  test "create OAuth2.Client from access_token map" do
    token = %{
      access_token: "66b1a87f7e7c39763fee984e423a3cb6c0117f60b30FAKE_TOKEN",
      expires_at: nil,
      other_params: %{},
      refresh_token: "67c185f56c8f748be134440e99ad6fbdfa5b26a52730a7FAKE_REFRESH",
      token_type: "Bearer"
    }

    assert %OAuth2.Client{} = FreshBex.get_client(token)
  end
end
