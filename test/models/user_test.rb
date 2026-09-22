require "test_helper"

# User モデルのテスト。
#
# モデルは hekireki が prisma/schema.prisma から生成するので、ここではスキーマに書いた
# 制約 (必須・一意・has_secure_password・normalizes) と、生成された翻訳が Rails 側で効いていることを確かめる。
class UserTest < ActiveSupport::TestCase
  test "メールアドレスの前後の空白を取り、小文字にそろえる" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")

    assert_equal "downcased@example.com", user.email_address
  end

  test "メールアドレスは必須" do
    user = User.new(email_address: "", password: "secret123")

    assert_not user.valid?
    # どのルールで弾かれたかは、言語に依存しない of_kind? で確かめる
    assert user.errors.of_kind?(:email_address, :blank)
  end

  test "メールアドレスは重複できない (大文字・小文字の違いも同じとみなす)" do
    user = User.new(email_address: "ALICE@example.com", password: "secret123")

    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :taken)
  end

  test "パスワードは必須" do
    user = User.new(email_address: "carol@example.com", password: "")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :blank)
    # password_digest の presence は password がないときは働かないので、エラーは password の 1 つだけ
    assert_equal [ :password ], user.errors.attribute_names
  end

  test "パスワードは 72 文字まで (bcrypt の上限)" do
    assert User.new(email_address: "carol@example.com", password: "a" * 72).valid?
    assert_not User.new(email_address: "carol@example.com", password: "a" * 73).valid?
  end

  test "パスワードと確認が一致しなければ無効" do
    user = User.new(email_address: "carol@example.com", password: "secret123", password_confirmation: "other")

    assert_not user.valid?
    assert user.errors.of_kind?(:password_confirmation, :confirmation)
  end

  test "パスワードは bcrypt のハッシュとして保存され、authenticate で照合できる" do
    user = User.create!(email_address: "carol@example.com", password: "secret123")

    assert_match(/\A\$2a\$/, user.password_digest)
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong")
  end

  test "authenticate_by はメールアドレスとパスワードが合うユーザーを返す" do
    assert_equal users(:alice), User.authenticate_by(email_address: "alice@example.com", password: "password")
    assert_nil User.authenticate_by(email_address: "alice@example.com", password: "wrong")
    assert_nil User.authenticate_by(email_address: "nobody@example.com", password: "password")
  end

  test "ユーザーを消すと、そのログイン (Session) も消える" do
    # スキーマの onDelete: Cascade から生成された dependent: :destroy
    user = users(:alice)

    assert_difference("Session.count", -user.sessions.count) do
      user.destroy!
    end
  end

  # バリデーションメッセージ。
  # 項目名とメッセージは hekireki が生成する config/locales/models/user/<言語>.yml と、
  # 仮想属性 (password) の分は config/locales/defaults/<言語>.yml から、
  # 項目名とメッセージのつなぎ方 (errors.format) は rails-i18n から来る。

  test "日本語: 空のメールアドレスとパスワード" do
    assert_equal [ "メールアドレスを入力してください", "パスワードを入力してください" ],
      full_messages(email_address: "", password: "")
  end

  test "英語: 空のメールアドレスとパスワード" do
    assert_equal [ "Email address can't be blank", "Password can't be blank" ],
      full_messages(email_address: "", password: "", locale: :en)
  end

  test "英語: 登録済みのメールアドレス" do
    assert_equal [ "Email address has already been taken" ],
      full_messages(email_address: "alice@example.com", password: "secret123", locale: :en)
  end

  private

  # 指定した言語で検証し、画面に出るのと同じ形のエラーメッセージを返す。
  #
  # @param email_address [String]
  # @param password [String]
  # @param locale [Symbol]
  # @return [Array<String>]
  def full_messages(email_address:, password:, locale: I18n.default_locale)
    I18n.with_locale(locale) do
      user = User.new(email_address:, password:)
      user.valid?
      user.errors.full_messages
    end
  end
end
