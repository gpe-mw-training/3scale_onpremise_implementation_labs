require_relative 'client'
require 'dotenv'

Dotenv.load
run Sinatra::Application
