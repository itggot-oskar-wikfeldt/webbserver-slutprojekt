#require 'slim'
#require 'sinatra'
#require 'bcrypt'
#require 'sqlite3'

require_relative 'modules.rb'

class App < Sinatra::Base
	include Users

	enable :sessions

	def set_error(error)
		session[:error] = error
	end

	def get_error
		error = session[:error]
		session[:error] = nil
		return error
	end

	get '/' do
		session[:page] = "/"
		db = SQLite3::Database.new('db/db.sqlite')
		db.results_as_hash = true
		posts = db.execute("SELECT * FROM posts")
		posts.each do |post|
			username = db.execute("SELECT name FROM users WHERE id=?", [post["user_id"]]).first["name"]
			post["username"] = username
			has_image = !post["image_url"].nil?
			post["has_image"] = has_image
		end

		

		slim(:index, locals:{posts:posts})
	end

	get '/hello' do
		session[:page] = "/hello"
		slim(:hello)
	end

	post('/login') do
		username = params["username"]
		password = params["password"]
		result = Users::login(username, password)
		if result.nil?
			set_error("invalid credentials")
			redirect(session[:page])			
		end
		session[:user_id] = result[:user_id]
		session[:username] = result[:username]
		set_error("")
		redirect(session[:page])
	end
	
	post('/logout') do
		page = session[:page]
		session.destroy
		redirect(page)
	end

	get('/register') do
		session[:registering] = true
		redirect(session[:page])
	end
	
	post('/register') do
		
		username = params["username"]
		password = params["password"]
		password_confirmation = params["confirm_password"]
		
		result = Users.register(username, password, password_confirmation)
		
		if result == 0
			set_error("registered! please log in")
			session[:registering] = nil
			redirect(session[:page])
		elsif result == 1000
			set_error("passwords don't match")
			redirect(session[:page])
		elsif result == 1001
			set_error("username already exists")
			redirect(session[:page])
		end
		
	end

	get('/post') do
		slim(:post)
	end

	post('/post') do
		db = SQL.new
		title = params[:title]
		image_url = params[:image]
		user_id = session[:user_id]
		db.insert_into("posts", ["title", "score", "user_id", "image_url"], [title, 0, user_id, image_url])
		redirect(session[:page])
	end

	get('/posts/:post_id') do
		db = SQL.new
		post_id = params[:post_id]
		session[:page] = "/posts/#{post_id}"
		session[:post_id] = post_id

		post = db.select(["*"], "posts", "id", post_id).first
		unless post
			slim(:fourofour)
		else
			username = db.select(["name"], "users", "id", post["user_id"]).first["name"]
			post["username"] = username

			comments = db.select(["*"], "comments", "post_id", post_id)
			comments.each do |comment|
				comment["username"] = db.select(["name"], "users", "id", comment["user_id"]).first["name"]
			end

			has_image = !post["image_url"].nil?

			slim(:posts, locals:{post:post, comments:comments, has_image:has_image})
		end
	end

	get('/users/:user_id') do
		db = SQL.new
		user_id = params[:user_id]
		user = db.select(["name"], "users", "id", user_id).first
		slim(:users, locals:{user:user})
	end

	post('/comment') do
		db = SQL.new
		text = params[:text]
		text = text[0...2000]
		user_id = session[:user_id]
		post_id = session[:post_id]

		p [text, user_id, post_id, 0].join(", ")

		db.insert_into("comments", ["text", "user_id", "post_id", "score"], [text, user_id, post_id, 0])
		redirect(session[:page])

	end

end           
