require "test_helper"

# HomeController のテスト。
#
# ログインが必要なページの振る舞い (未ログインならログイン画面へ、ログイン中なら表示) を確かめる。
class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "未ログインで開くと、ログイン画面へ送られる" do
    get root_url

    assert_redirected_to new_session_url
  end

  test "URL に言語がなければ、日本語で表示する" do
    sign_in_as @user
    get "/"

    assert_select "h1", "ホーム"
  end

  test "対応していない言語の URL は 404 になる" do
    get "/fr"

    assert_response :not_found
  end

  test "ログイン中なら、メールアドレスとログイン履歴が出る" do
    sign_in_as @user
    get root_url

    assert_response :success
    assert_select "p", /alice@example.com でログインしています/
    # fixtures のログイン 1 件と、sign_in_as で作った 1 件
    assert_select "#sessions li", count: 2
    assert_select "#sessions li", text: /このブラウザ/, count: 1
  end

  test "他のユーザーのログイン履歴は出ない" do
    sign_in_as users(:bob)
    get root_url

    assert_select "#sessions li", count: 1
    assert_select "#sessions li", text: /Macintosh/, count: 0
  end

  test "Cookie の Session が消えていれば、未ログインとして扱う" do
    sign_in_as @user
    Current.session.destroy!

    get root_url

    assert_redirected_to new_session_url
  end
end
