require 'sinatra'
require 'securerandom'

enable :sessions
set :session_secret, '*&(^B234'

B_APP_URL = ENV['B_APP_URL'] || "http://localhost:8081/helloworld"
CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
REDIRECT_URI = ENV['REDIRECT_URI'] || "http://localhost:3001/callback"
AUTHORIZE_ENDPOINT = ENV['AUTHORIZE_ENDPOINT'] || "http://localhost:8080/authorize"
TOKEN_ENDPOINT = ENV['TOKEN_ENDPOINT'] || "http://localhost:8080/oauth/token"

get("/") do
  @state = SecureRandom.uuid
  session[:state] = @state
	erb :root
end

get("/callback") do
	@code = params[:state] == session[:state] ? params[:code] : "error: state does not match"
	erb :root
end
