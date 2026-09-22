require "test_helper"

# SessionsController のテスト。
#
# ログイン・ログアウトを HTTP リクエストとして送り、リダイレクト先と Cookie、Session の行を確かめる。
class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "ログイン画面を表示できる" do
    get new_session_url

    assert_response :success
    assert_select "h1", "ログイン"
  end

  test "URL の言語が英語なら、画面も英語になる" do
    get new_session_url(locale: :en)

    assert_select "h1", "Sign in"
  end

  test "正しいメールアドレスとパスワードでログインできる" do
    assert_difference("@user.sessions.count") do
      post session_url, params: { email_address: @user.email_address, password: "password" }
    end

    assert_redirected_to root_url
    assert cookies[:session_id]
  end

  test "ログイン後は、トップページにログイン中のユーザーが出る" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!

    assert_select "p", /alice@example.com でログインしています/
  end

  test "メールアドレスの大文字と前後の空白は無視してログインできる" do
    # User の normalizes は、保存時だけでなく authenticate_by の検索条件にも効く
    post session_url, params: { email_address: "  ALICE@example.com ", password: "password" }

    assert_redirected_to root_url
  end

  test "ログイン前に開こうとしたページに、ログイン後に戻る" do
    get root_url(locale: :en)
    assert_redirected_to new_session_url(locale: :en)

    post session_url(locale: :en), params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_url(locale: :en)
  end

  test "パスワードが違うとログインできず、ログイン画面に戻す" do
    assert_no_difference("Session.count") do
      post session_url, params: { email_address: @user.email_address, password: "wrong" }
    end

    assert_redirected_to new_session_url
    assert_nil cookies[:session_id]

    follow_redirect!
    # どちらが違うかは伝えない
    assert_select "[role=alert]", "メールアドレスかパスワードが違います。"
  end

  test "登録されていないメールアドレスでもログインできない" do
    post session_url, params: { email_address: "nobody@example.com", password: "password" }

    assert_redirected_to new_session_url
    assert_nil cookies[:session_id]
  end

  test "英語の画面では、エラーメッセージも英語になる" do
    post session_url(locale: :en), params: { email_address: @user.email_address, password: "wrong" }
    follow_redirect!

    assert_select "[role=alert]", "Try another email address or password."
  end

  test "ログアウトすると Session の行が消え、Cookie も使えなくなる" do
    sign_in_as @user

    assert_difference("Session.count", -1) do
      delete session_url
    end

    # DELETE の後は 303 でリダイレクトする
    assert_response :see_other
    assert_redirected_to new_session_url
    assert_empty cookies[:session_id]
  end

  test "ログアウト後にトップページを開くと、ログイン画面へ送られる" do
    sign_in_as @user
    delete session_url

    get root_url

    assert_redirected_to new_session_url
  end
end
