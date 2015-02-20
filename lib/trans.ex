defmodule Trans do
  use Application
	require Logger

	def start(_type, _args) do
		import Supervisor.Spec, warn: false

		Logger.debug("Trans started")

		children = [
								 worker(Trans.Translator, [])
						 ]
    opts = [strategy: :one_for_one, name: Trans.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
