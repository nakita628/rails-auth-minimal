# コントローラのテストでログイン状態を作るヘルパー。`bin/rails generate authentication` が作るものと同じ。
#
# アプリと同じく Session の行を作り、その ID を署名付き Cookie `session_id` に入れる。
# 署名は本物のリクエストと同じ鍵 (Rails.application.key_generator) で作られるので、
# 以後の get / post はログイン中として扱われる。
module SessionTestHelper
  # @param user [User]
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
