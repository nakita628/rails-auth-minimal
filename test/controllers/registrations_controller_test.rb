require "test_helper"

# RegistrationsController のテスト。
#
# アカウント登録を HTTP リクエストとして送り、ユーザーの作成、ログイン状態、バリデーションエラーの表示を確かめる。
class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "登録画面を表示できる" do
    get new_registration_url

    assert_response :success
    assert_select "h1", "アカウント登録"
  end

  test "登録すると、ユーザーが作られてログイン状態になる" do
    assert_difference([ "User.count", "Session.count" ]) do
      post registration_url, params: { user: { email_address: "carol@example.com", password: "secret123", password_confirmation: "secret123" } }
    end

    assert_redirected_to root_url
    assert cookies[:session_id]
    # パスワードは平文では保存されず、bcrypt のハッシュとして入る
    user = User.find_by!(email_address: "carol@example.com")
    assert_not_equal "secret123", user.password_digest
    assert user.authenticate("secret123")
  end

  test "メールアドレスは小文字にそろえて保存する" do
    post registration_url, params: { user: { email_address: " Carol@Example.com ", password: "secret123", password_confirmation: "secret123" } }

    assert User.exists?(email_address: "carol@example.com")
  end

  test "メールアドレスが空だと登録できず、422 で登録画面を描き直す" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "", password: "secret123", password_confirmation: "secret123" } }
    end

    # 入力エラーは 422 (Unprocessable Content) で、同じ画面をエラー付きで描き直す
    assert_response :unprocessable_content
    assert_select "[role=alert] li", "メールアドレスを入力してください"
  end

  test "パスワードが空だと登録できない" do
    post registration_url, params: { user: { email_address: "carol@example.com", password: "", password_confirmation: "" } }

    assert_response :unprocessable_content
    # password_digest の分のエラーは出ず、パスワードのエラーだけが 1 つ出る
    assert_select "[role=alert] li", count: 1
    assert_select "[role=alert] li", "パスワードを入力してください"
  end

  test "パスワードと確認が一致しないと登録できない" do
    post registration_url, params: { user: { email_address: "carol@example.com", password: "secret123", password_confirmation: "different" } }

    assert_response :unprocessable_content
    assert_select "[role=alert] li", "パスワード (確認)とパスワードの入力が一致しません"
  end

  test "登録済みのメールアドレスでは登録できない" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "ALICE@example.com", password: "secret123", password_confirmation: "secret123" } }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert] li", "メールアドレスはすでに登録されています"
  end

  test "英語の画面では、エラーメッセージも英語になる" do
    post registration_url(locale: :en), params: { user: { email_address: "", password: "", password_confirmation: "" } }

    assert_response :unprocessable_content
    assert_select "[role=alert] li", "Email address can't be blank"
    assert_select "[role=alert] li", "Password can't be blank"
  end

  test "英語の画面で登録すると、英語のトップページに進む" do
    post registration_url(locale: :en), params: { user: { email_address: "carol@example.com", password: "secret123", password_confirmation: "secret123" } }

    assert_redirected_to root_url(locale: :en)
  end
end
