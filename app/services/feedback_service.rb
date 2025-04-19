require 'anthropic'

class FeedbackService
  attr_reader :post
  class ClaudeApiError < StandardError; end

  def initialize(post)
    @post = post
  end

  def generate_feedback
    api_key = Rails.application.credentials.dig(:anthropic, :api_key)
    unless api_key
      Rails.logger.error "Anthropic API key is not configured."
      raise ClaudeApiError, "APIキーが設定されていません。"
    end

    client = Anthropic::Client.new(api_key: api_key)

    # JSONフォーマットのレスポンスを要求するシステムプロンプト
    system_prompt = <<~PROMPT
      あなたは優秀な文章レビューアシスタントです。以下の投稿内容について分析し、必ず以下の完全なJSONフォーマットで結果を返してください。余計なテキストは含めないでください。

      {
        "score": 0〜100の整数値（文章の質を総合的に評価）,
        "criteria_scores": {
          "clarity": 0〜25の整数値,
          "structure": 0〜25の整数値,
          "conciseness": 0〜25の整数値,
          "persuasiveness": 0〜25の整数値
        },
          "feedback": "フィードバックテキスト"
        }
        
        フィードバックテキストは、必ず以下のフォーマットで記述してください:
        
        1. 各セクションは必ずMarkdown見出し形式（##や###）で記述する
        2. 各見出しの後には必ず空行を入れる
        3. 箇条書きには必ず - の前後にスペースを入れる
        4. 以下の順序と構造を厳密に守る:
          
          ## 総合評価

          [総合的な評価コメント]

          ## 良い点

          - [良い点1]
          - [良い点2]
          - [良い点3]

          ## 更に良くできる点

          - [改善提案1]
          - [改善提案2]
          - [改善提案3]

          ## 各基準の詳細

          ### 明確さ（X/25点）

          [具体的なコメント]

          ### 構成（X/25点）

          [具体的なコメント]

          ### 簡潔さ（X/25点）

          [具体的なコメント]

          ### 説得力（X/25点）

          [具体的なコメント]


      評価基準の詳細：
      1. 明確さ (25点)：
        - 20-25点：非常に明確で理解しやすい
        - 15-19点：概ね明確だが、一部分かりにくい箇所がある
        - 10-14点：理解するのに少し努力が必要
        - 0-9点：意味が不明確な部分が多い

      2. 構成 (25点)：
        - 20-25点：論理的な流れが完璧
        - 15-19点：全体的に良い構成だが、一部改善の余地あり
        - 10-14点：構成にやや一貫性がない
        - 0-9点：構成が混乱している

      3. 簡潔さ (25点)：
        - 20-25点：無駄な言葉がなく簡潔
        - 15-19点：ほぼ簡潔だが、一部冗長
        - 10-14点：やや冗長な表現が目立つ
        - 0-9点：全体的に冗長

      4. 説得力 (25点)：
        - 20-25点：非常に説得力がある
        - 15-19点：説得力はあるが、一部弱い論点がある
        - 10-14点：主張の裏付けが不十分
        - 0-9点：説得力に欠ける

      必ず完全なJSONオブジェクトだけを返してください。前後に余計なテキストを含めないでください。正確なJSON構文を維持してください。
    PROMPT

    user_message_content = <<~CONTENT
      # 投稿タイトル:
      #{post.title}

      # 投稿内容:
      #{post.content}
    CONTENT

    begin
      response = client.messages.create(
        model: "claude-3-5-sonnet-20241022",
        system: system_prompt,
        messages: [
          { role: "user", content: user_message_content }
        ],
        max_tokens: 1024,
        temperature: 0.3
      )

      # レスポンステキストを取得
      response_text = response.content&.first&.text

      if response_text.present?
        begin
          # 1. 正規表現を使ってJSON部分を抽出する試み
          if response_text =~ /\{.*\}/m
            json_text = $&  # マッチした部分を取得
            
            # 2. 制御文字を除去
            json_text = json_text.gsub(/[\u0000-\u001F\u007F-\u009F]/, '')
            
            # 3. JSONとしてパース
            parsed_response = JSON.parse(json_text)
            
            # feedbackとscoreを抽出
            feedback = parsed_response["feedback"]
            score = parsed_response["score"].to_i
            
            # スコアの範囲を確認
            score = 0 if score < 0
            score = 100 if score > 100
            
            # エスケープされた改行文字を実際の改行に変換
            feedback = feedback.gsub('\\n', "\n") if feedback.is_a?(String)
            # 見出しの前に改行を追加して見出しが適切に表示されるようにする
            feedback = feedback.gsub(/## /, "\n## ").gsub(/### /, "\n### ") if feedback.is_a?(String)
            # 特殊なパターン "#\n## " を "### " に置換する
            feedback = feedback.gsub(/#\s*\n\s*## /, "### ") if feedback.is_a?(String)
            # 冒頭の余分な改行を削除
            feedback = feedback.sub(/\A\n+/, '') if feedback.is_a?(String)

            # postを更新
            post.update!(
              ai_feedback: feedback,
              ai_score: score,
              ai_feedback_status: 'completed'
            )
            
            Rails.logger.info "AI feedback and score generated successfully for Post ID: #{post.id}, Score: #{score}"
          else
            # JSON形式が検出できない場合
            Rails.logger.error "No JSON format detected in response for Post ID: #{post.id}"
            post.update!(
              ai_feedback: "フィードバック形式エラー。JSONフォーマットが検出できませんでした。\n\n#{response_text}",
              ai_score: nil,
              ai_feedback_status: 'completed'
            )
          end
        rescue JSON::ParserError => e
          # JSON解析エラー時
          Rails.logger.error "JSON parsing error for Post ID: #{post.id}: #{e.message}"
          
          # バックアップ方法: 正規表現で直接スコアを抽出する
          score_match = response_text.match(/"score":\s*(\d+)/)
          score = score_match ? score_match[1].to_i : nil
          
          if score
            # スコアが抽出できた場合、フィードバックも正規表現で抽出を試みる
            feedback_match = response_text.match(/"feedback":\s*"(.*?)(?<!\\)"(?=,)/m)
            feedback = feedback_match ? feedback_match[1] : "フィードバック抽出エラー。以下が生成されたテキストです：\n\n#{response_text}"
            
            post.update!(
              ai_feedback: feedback,
              ai_score: score,
              ai_feedback_status: 'completed'
            )
            Rails.logger.info "Recovered feedback and score for Post ID: #{post.id} using regex, Score: #{score}"
          else
            # スコアも抽出できなかった場合
            post.update!(
              ai_feedback: "フィードバック形式エラー。以下が生成されたテキストです：\n\n#{response_text}",
              ai_score: nil,
              ai_feedback_status: 'completed'
            )
          end
        end
      else
        Rails.logger.warn "Empty response received for Post ID: #{post.id}"
        post.update!(
          ai_feedback: "AIからの応答が空でした。",
          ai_score: nil,
          ai_feedback_status: 'failed'
        )
      end

    rescue Anthropic::Errors::APIError => e
      # APIレスポンスの情報を取得するために、エラーオブジェクトの構造に合わせて修正
      error_info = e.respond_to?(:response_body) ? e.response_body : e.to_h
      status = e.respond_to?(:status) ? e.status : "unknown"
      
      Rails.logger.error "Anthropic API error for Post ID: #{post.id}: Status=#{status}, Response=#{error_info}, Message=#{e.message}"
      raise ClaudeApiError, "Claude APIとの通信に失敗しました: #{e.message} (Status: #{status})"
    rescue StandardError => e
      Rails.logger.error "Unexpected error during feedback generation for Post ID: #{post.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise ClaudeApiError, "予期せぬエラーが発生しました: #{e.message}"
    end
  end
end