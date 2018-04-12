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
		slim(:index)
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

end           
