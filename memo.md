# current_userをprivateに含めない方がいい理由

def create
  @post = Post.new(post_params)
end

private
def post_params
  params.require(:post).permit(:title, :content, :draft_flag).merge(user_id: current_user.id)
end

## ざっくり結論
current_userはある場合とない場合で動作が変わるから、paramsに乗っけるのではなく、直接コントローラの動作に記述すべき

1. 実行コンテキストの安全性の問題

現在のユーザーへの依存：post_params 内で current_user を使用すると、そのメソッドはコントローラーのコンテキストに強く依存します
エラーリスク：将来、current_user が利用できない状況（例：バックグラウンドジョブ、別のコントローラーでの再利用）でエラーが発生する可能性があります

2. Strong Parametersの本来の意図との不一致

本来の目的：Strong Parametersはリクエストからの外部入力を安全にフィルタリングするためのもの
概念の混同：user_id はフォームから送信される値ではなく、サーバー側で設定する値なので、Strong Parametersに含めるのは概念的に不適切

3. 関心の分離（Separation of Concerns）

責任の明確さ：「パラメータの許可・拒否」と「ユーザーとの関連付け」は別の関心事
コードの意図：current_user.posts.build は「このユーザーの投稿を作る」という意図が明確

4. コードの保守性と再利用性

機能拡張時の問題：例えば、管理者が別のユーザーの代わりに投稿を作成する機能を追加する場合、post_params の実装変更が必要
テスト困難性：post_params にアプリケーションロジックが含まれると、ユニットテストが複雑になる

5. Railsコミュニティの標準的実践

慣習に従う利点：Railsの標準的なアプローチに従うことで、コードが読みやすく、他の開発者が理解しやすくなる
将来の開発者のため：標準的なパターンを使うことで、将来のチームメンバーが混乱せずコードを理解できる

これらの理由から、関連付けを通じたオブジェクト生成（current_user.posts.build(post_params)）が推奨されています。


# モデル属性とデータベースカラムの対応関係
データがどのカラムに保存されるかについて、整理して説明します。
## モデル属性とデータベースカラムの対応
コピーモデルの属性               | データベースのカラム
--------------------------|------------------
@post.title               | title
@post.content             | content
@post.word_count          | word_count
@post.draft_flag          | draft_flag
@post.user_id             | user_id

## 値がセットされる方法（複数ある）
- ストロングパラメータから直接
@post = Post.new(post_params)
params[:post][:title] → @post.title → データベースの title カラム

- 関連付けから自動設定
@post = current_user.posts.build(post_params)
current_user.id → @post.user_id → データベースの user_id カラム

- 明示的にコードで設定
@post.word_count = count_words(@post.content)
計算結果 → @post.word_count → データベースの word_count カラム

つまり、値を設定する方法は複数ありますが、最終的にはすべて対応するカラムに保存されるということです。
@post.save を実行すると、その時点での @post オブジェクトの全属性が対応するデータベースカラムに保存されます。設定方法に関わらず、すべての属性値がデータベースに反映されます。
