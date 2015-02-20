defmodule Trans.Translator do
	@moduledoc """
A translator
"""

	@name __MODULE__
  @group :translator
	use GenServer
  require Logger
  
  def start_link() do
		GenServer.start_link(@name, [])
  end

  def init(_) do
		:pg2.start
		:pg2.create(@group)
		:pg2.join(@group, self)
    {:ok, []}
  end

  def handle_call({:translate, text, from, to}, caller, state) do
		Logger.debug("Translating #{text}")
		{:reply, {:ok, "Le #{text}"}, state}
  end

end
