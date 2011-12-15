require 'rubygems'
require 'sinatra'
require 'haml'
require 'linkedin'
require 'yaml'
require 'set'

#get your application key and secret at http://developer.linkedin.com
#and edit config.yml accordingly
CONFIG = YAML.load_file 'config.yml'
api_key = CONFIG['api_key']
secret_key = CONFIG['secret_key']
#this is where the app lives, e.g. "http://localhost:4567"
app_url = CONFIG['app_url']

use Rack::Session::Pool

buzzwords = [:creative, :organizational, :effective, :motivated, :innovative, :dynamic]
buzzphrases = ['extensive_experience', 'track_record', 'problem_solving', 'communication_skills']

get '/' do
  client = LinkedIn::Client.new(api_key, secret_key)
  if session[:credentials] == nil
    rtoken = client.request_token(:oauth_callback => app_url + "/authorize")
    rsecret = rtoken.secret
    session[:rtoken] = rtoken
    session[:rsecret] = rsecret
    redirect rtoken.authorize_url
  end
  client.authorize_from_access(session[:credentials][0], session[:credentials][1])
  prof = client.profile(:fields => [:summary, :headline, 'first-name', 'last-name'])
  @name = prof['first-name'] + ' ' + prof['last-name']
  head, sum = prof[:headline].downcase, prof[:summary].downcase
  buzzphrases.each do |bf|
    head.gsub!(bf.gsub('_', ' '), bf)
    sum.gsub!(bf.gsub('_', ' '), bf)
  end
  words = head != nil ? head.split(/[\s.]/) : []
  words += (sum != nil ? sum.split(/[\s.]/) : [])

  @offenders = Set.new
  buzz = Set.new(buzzwords + buzzphrases)
  words.each do |w|
    if buzz.include? w
      @offenders.add w
    end
  end
  @offenders.each {|x| puts x} 
  haml :index
 end 

get '/authorize' do
  pin = params[:oauth_verifier]
  client = LinkedIn::Client.new(api_key, secret_key)
  credentials = client.authorize_from_request(params[:oauth_token], session[:rsecret], pin)
  session[:credentials] = credentials
  redirect '/'
end

