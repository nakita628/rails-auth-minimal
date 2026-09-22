require "test_helper"

# Session モデルのテスト。
#
# スキーマの関連 (belongs_to :user) と並び順 (recent) が Rails 側で効いていることを確かめる。
class SessionTest < ActiveSupport::TestCase
  test "ユーザーは必須" do
    session = Session.new

    assert_not session.valid?
    assert session.errors.of_kind?(:user, :blank)
  end

  test "IP アドレスとブラウザは省略できる" do
    assert users(:alice).sessions.build.valid?
  end

  test "recent は新しい順に並べる" do
    # スキーマの `@ar.scope :recent` から生成された scope。fixtures には created_at を書いていないので、ここで作る
    user = users(:bob)
    older = user.sessions.create!(created_at: 2.days.ago)
    newer = user.sessions.create!(created_at: 1.day.ago)

    assert_equal [ newer, older ], user.sessions.recent.to_a
  end

  test "日本語: ユーザーがない" do
    session = Session.new
    session.valid?

    assert_equal [ "ユーザーを入力してください" ], session.errors.full_messages
  end
end
