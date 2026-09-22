# YARD の拡張 (.yardopts の --load で読み込む)。アプリからは使わない。
#
# YARD はメソッド一覧に出す要約 (コメントの最初の文) の末尾に "." を付け足す。
# 「。」で終わる日本語の文だと「〜する。.」になってしまうので、その "." だけを外す。
module JapaneseSummary
  def summary
    super.sub(/。\.\z/, "。")
  end
end

YARD::Docstring.prepend(JapaneseSummary)
