class App < Sinatra::Base

	enable :sessions

	get '/' do
		slim(:index)
	end

end           
