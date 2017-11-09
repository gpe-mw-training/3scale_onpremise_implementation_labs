require 'sinatra'
require 'securerandom'

enable :sessions
set :session_secret, '*&(^B234'

GATEWAY = ENV['GATEWAY'] || "http://localhost:8080"
CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
REDIRECT_URI = ENV['REDIRECT_URI'] || "http://localhost:3001/callback"
AUTHORIZE_ENDPOINT = "#{GATEWAY}/authorize"
TOKEN_ENDPOINT = "#{GATEWAY}/oauth/token"

get("/") do
  @state = SecureRandom.uuid
  session[:state] = @state
	erb :root
end

get("/callback") do
	@code = params[:state] == session[:state] ? params[:code] : "error: state does not match"
	erb :root
end
