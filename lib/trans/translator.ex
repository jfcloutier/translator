defmodule Trans.Translator do
	@moduledoc """
A translator registered on process group possibly with other translators.
Accesses Google Translate to translate short texts.
"""

	alias Poison, as: Json
	
  @name __MODULE__
  @group :translators # the name of the translators process group

  @url "https://www.googleapis.com/language/translate/v2"

	use GenServer
  require Logger
  
  ### API

  def start_link() do
		GenServer.start_link(@name, [])
  end

 ## Callbacks

  # Starts process group management and create a group for translators (no effect if already started)
	# Join the group
  # The state is a cache of all translations already done
  def init(_) do
		:pg2.start
		:pg2.create(@group)
		:pg2.join(@group, self)
    {:ok, HashDict.new}
  end

  # Translation request with text, target language and API key
  def handle_call({:translate, text, to, key}, _caller, state) do
		Logger.debug("Translating \"#{text}\" to #{to}")
		result = translate(text, to, key, state)
		case result do
			{:ok, translation} ->
				{:reply, {:ok, translation}, Dict.put(state, hash(text, to), translation)}
      error ->
				Logger.debug("Failed to translate: #{inspect error}")
				{:reply, {:error, "Translation failed"}, state}
    end
  end

  ### PRIVATE

  # Create key for caching a translation
  defp hash(text, to) do
		"#{to} => #{text}"
  end

  # First look for a cached translation then ask Google Translate
	defp translate(text, to, key, state) do		
		case Dict.get(state, hash(text, to)) do
			nil ->
				google_translate(text, to, key)
		  translation ->
				{:ok, translation}
    end
  end

  # Query Google Translate
	defp google_translate(nil, _to, _key) do
		{:error, "No text"}
  end
  defp google_translate(text, to, key) do
		Logger.debug("Accessing Google Translate")
		query = "#{@url}?q=#{URI.encode(text)}&target=#{to}&key=#{key}"
    try do
			response = HTTPotion.get(query, [timeout: 10_000])
			if HTTPotion.Response.success?(response) do
				translation_from(response.body) # Extract the translation
			else
				{:error, "Translation failed"}
			end
    catch # Capture errors
			kind,reason -> Logger.debug( "Failed to translate: #{inspect kind} , #{inspect reason}")
                     {:error, "Translation failed"}
    end
  end

	# Extract the translation from the body of the response from Google Translate
	defp translation_from(body) do
		result = Json.decode!(body)
    case result["data"]["translations"] do
			[translation|_] -> {:ok, translation["translatedText"]}
      [] -> {:error, "No translation found"}
    end
  end

end
