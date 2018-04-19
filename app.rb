#require 'slim'
#require 'sinatra'
#require 'bcrypt'
#require 'sqlite3'

class App < Sinatra::Base

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
		end

		slim(:index, locals:{posts:posts})
	end

	

	get '/hello' do
		session[:page] = "/hello"
		slim(:hello)
	end

	post('/login') do
		db = SQLite3::Database.new('db/db.sqlite')
		db.results_as_hash = true
		username = params["username"]
		password = params["password"]
		
		result = db.execute("SELECT id, password_digest FROM users WHERE name=?", [username])

		if result.empty?
			set_error("invalid credentials")
			redirect(session[:page])			
		end

		user_id = result.first["id"]
		password_digest = result.first["password_digest"]
		if BCrypt::Password.new(password_digest) == password
			session[:user_id] = user_id
			session[:username] = db.execute("SELECT name FROM users WHERE id = ?", [session[:user_id]]).first["name"]
			set_error("")
			redirect(session[:page])
		else
			set_error("invalid credentials")
			redirect(session[:page])
		end
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
		db = SQLite3::Database.new('db/db.sqlite')
		db.results_as_hash = true
		
		username = params["username"]
		password = params["password"]
		password_confirmation = params["confirm_password"]
		
		result = db.execute("SELECT id FROM users WHERE name=?", [username])
		
		if result.empty?
			if password == password_confirmation
				password_digest = BCrypt::Password.create(password)
				
				db.execute("INSERT INTO users(name, password_digest) VALUES (?,?)", [username, password_digest])
				set_error("registered! please log in")
				session[:registering] = nil
				redirect(session[:page])
			else
				set_error("passwords don't match")
				redirect(session[:page])
			end
		else
			set_error("username already exists")
			redirect(session[:page])
		end
		
	end

	get('/post') do
		slim(:post)
	end

	post('/post') do
		db = SQLite3::Database.new('db/db.sqlite')
		title = params[:title]
		image = params[:image]
		user_id = session[:user_id]
		db.execute("INSERT INTO posts (title, score, user_id) VALUES (?, ?, ?)", [title, 0, user_id])
		redirect(session[:page])
	end

	get('/posts/:post_id') do
		db = SQLite3::Database.new('db/db.sqlite')
		db.results_as_hash = true
		post_id = params[:post_id]
		session[:page] = "/posts/#{post_id}"

		post = db.execute("SELECT * FROM posts WHERE id = ?", [post_id]).first
		unless post
			slim(:fourofour)
		else
			username = db.execute("SELECT name FROM users WHERE id=?", [post["user_id"]]).first["name"]
			post["username"] = username

			slim(:posts, locals:{post:post})
		end

	end

end           
