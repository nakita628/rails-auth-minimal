# ログイン状態の管理。`bin/rails generate authentication` が作るものをもとにしている。
#
# ApplicationController に include され、すべてのアクションでログインを必須にする。
# ログインなしで見せるアクションは、コントローラで `allow_unauthenticated_access` を呼んで外す。
#
# 仕組み:
# 1. ログイン時に Session の行を 1 件作り、その ID を署名付き Cookie `session_id` に入れる (#start_new_session_for)
# 2. 以後のリクエストでは Cookie の ID で Session を探し、Current.session に入れる (#resume_session)
# 3. ログアウトで Session の行を消し、Cookie も消す (#terminate_session)
#
# Cookie は署名されているので改ざんできず、行を消せばその Cookie は使えなくなる。
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    # 指定したアクションを、ログインなしでも見られるようにする。
    #
    # @param options [Hash] skip_before_action に渡すオプション (`only:` / `except:`)
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  # ログインしているか。ビューからも呼べる (helper_method)。
  #
  # @return [Boolean]
  def authenticated?
    resume_session
  end

  # ログインしていなければ、ログイン画面へ送る。
  def require_authentication
    resume_session || request_authentication
  end

  # Cookie からログイン中の Session を復元し、Current.session に入れる。
  #
  # @return [Session, nil]
  def resume_session
    Current.session ||= find_session_by_cookie
  end

  # @return [Session, nil]
  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  # 見ようとした URL を覚えてから、ログイン画面へリダイレクトする。
  # ログイン後は #after_authentication_url でその URL に戻る。
  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  # ログイン後に戻る URL。覚えていなければトップページ。
  #
  # @return [String]
  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  # ユーザーの Session を作り、その ID を署名付き Cookie に入れてログイン状態にする。
  #
  # Cookie は httponly (JavaScript から読めない) と same_site: :lax (他サイトからのフォーム送信では送られない) にする。
  #
  # @param user [User]
  # @return [Session]
  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end
  end

  # Session の行と Cookie を消してログアウトする。
  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
