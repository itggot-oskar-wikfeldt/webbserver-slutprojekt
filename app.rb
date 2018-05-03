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
		db = SQL.new
		posts = db.execute("SELECT * FROM posts")
		posts.each do |post|
			username = db.execute_with_vars("SELECT name FROM users WHERE id=?", [post["user_id"]]).first["name"]
			post["username"] = username
			has_image = !post["image_url"].nil?
			post["has_image"] = has_image
		end

		slim(:index, locals:{posts:posts})
	end

	get '/friends' do
		session[:page] = "/friends"
		friends = false
		if session[:user_id]
			friends = Users::get_friends(session[:user_id])		
		end
		slim(:friends, locals:{friends:friends})

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

	post('/no_register') do
		session[:registering] = false
		redirect(session[:page])
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
		other_user_id = params[:user_id]
		session[:page] = "/users/#{other_user_id}"
		session[:other_user_id] = other_user_id
		username = db.select(["name"], "users", "id", other_user_id).first
		friends_with = false
		if session[:user_id]
			friends = Users::get_friends(session[:user_id])
			friends.each do |friend|
				if friend[:id].to_i == other_user_id.to_i
					friends_with = true
				end
			end
		end
		slim(:users, locals:{user:username, friends_with:friends_with})
	end

	post('/add_friend') do
		db = SQL.new
		user_id = session[:user_id]
		friend_id = session[:other_user_id]
		
		friends = Users::get_friends(user_id)
		friends.each do |friend|
			if friend[:id].to_i == friend_id.to_i
				redirect(session[:page])
				return
			end
		end
		db.insert_into("friends_with_benefits", ["user_1", "user_2"], [user_id, friend_id])
		redirect(session[:page])
	end

	post('/comment') do
		db = SQL.new
		text = params[:text]
		text = text[0...2000]
		user_id = session[:user_id]
		post_id = session[:post_id]
		db.insert_into("comments", ["text", "user_id", "post_id", "score"], [text, user_id, post_id, 0])
		redirect(session[:page])

	end

end           
