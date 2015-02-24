Translator
==========

A demo Elixir/OTP Web application that:

1. Registers itself in a process group on a cluster
2. Accesses the Google Translate API to translate short texts when requested by https://github.com/jfcloutier/hacker_news

This was developed for the Portland (Maine) Erlang & Elixir Meetup 

To start:

1. Execute: iex --name something_unique@your_ip_address --cookie oreo
2. Join the cluster: iex> Node.connect(:"name_of_hacker_news_node") 

At least one translator node must be started.
