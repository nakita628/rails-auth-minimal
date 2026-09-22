# リクエストの間だけ有効な、今のログイン情報の置き場所 (ActiveSupport::CurrentAttributes)。
#
# Authentication#resume_session が Cookie から見つけた Session をここに入れ、
# コントローラやビューは `Current.user` でログイン中のユーザーを取り出す。
# リクエストが終わると自動的に空に戻るので、別のリクエストに持ち越されることはない。
#
# app/models/ の他のファイルは hekireki が生成するが、このファイルはテーブルを持たないので手で書く。
class Current < ActiveSupport::CurrentAttributes
  # 今のリクエストのログイン (Session)。未ログインなら nil。
  attribute :session

  # ログイン中のユーザー。未ログインなら nil。
  delegate :user, to: :session, allow_nil: true
end
