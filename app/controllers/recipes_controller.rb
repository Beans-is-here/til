require 'json'
class RecipesController < ApplicationController
  def new
    # newアクションでも@recipeを初期化しておくと、ビューでの条件分岐がシンプルになります
    @recipe = nil
  end

  def create
    ingredients = params[:ingredients]

    prompt = <<-PROMPT
    「#{ingredients}」という食材を使った、家庭で簡単に作れるレシピを1つ提案してください。
    以下のJSON形式で、キーや値の型も完全に守って応答してください。

    {
      "recipeName": "料理名",
      "description": "料理の簡単な説明",
      "ingredients": [
        { "name": "材料名", "quantity": "分量" }
      ],
      "instructions": [
        "手順1",
        "手順2"
      ]
    }
    PROMPT

    client = OpenAI::Client.new

    begin

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        response_format: { type: "json_object" },
        temperature: 0.7,
      }
    )

    raw_response = response.dig("choices", 0, "message", "content")
    @recipe = JSON.parse(raw_response)

    rescue OpenAI::Error => e
      # APIエラーが発生した場合の処理
      @error_message = "AIとの通信中にエラーが発生しました: #{e.message}"
    rescue JSON::ParserError => e
      # JSONのパースに失敗した場合の処理
      @error_message = "AIからの応答を正しく解析できませんでした。もう一度お試しください。"
    end

    # createアクションの後、newテンプレートを再描画する
    # これにより、@recipe変数がnew.html.erbで使えるようになります
    render :new, status: :ok
  end
end
