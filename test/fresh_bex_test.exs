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
end
