defmodule Trans.Translator do
	@moduledoc """
A translator
"""

	alias Poison, as: Json
	
  @name __MODULE__
  @group :translators

  @url "https://www.googleapis.com/language/translate/v2"

	use GenServer
  require Logger
  
  def start_link() do
		GenServer.start_link(@name, [])
  end

  def init(_) do
		:pg2.start
		:pg2.create(@group)
		:pg2.join(@group, self)
    {:ok, HashDict.new}
  end

  def handle_call({:translate, text, to, key}, _caller, state) do
		Logger.debug("Translating \"#{text}\" to #{to}")
		result = translate(text, to, key, state)
		case result do
			{:ok, translation} ->
				{:reply, {:ok, translation}, Dict.put(state, hash(text, to), translation)}
      error ->
				{:reply, error, state}
    end
  end

  defp hash(text, to) do
		"#{to} => #{text}"
  end

	defp translate(text, to, key, state) do		
		case Dict.get(state, hash(text, to)) do
			nil ->
				google_translate(text, to, key)
		  translation ->
				{:ok, translation}
    end
  end

  defp google_translate(text, to, key) do
		Logger.debug("Accessing Google Translate")
		query = "#{@url}?q=#{URI.encode(text)}&target=#{to}&key=#{key}"
    try do
			response = HTTPotion.get(query)
			# Logger.debug("Response: #{inspect response}")
			if HTTPotion.Response.success?(response) do
				translation_from(response.body)
			else
				{:error, "Failed to retrieve translation"}
			end
    catch
			error -> {:error, "#{inspect error}"}
    end
  end

	defp translation_from(body) do
		result = Json.decode!(body)
    # Logger.debug("Decoded: #{inspect result}")
    case result["data"]["translations"] do
			[translation|_] -> {:ok, translation["translatedText"]}
      [] -> {:error, "no translation found"}
    end
  end

end
