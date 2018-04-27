class SQL
    def initialize
        @db = SQLite3::Database.new('db/db.sqlite')
        @db.results_as_hash = true
    end

    def select(select_columns, from_table, compare_column, value)
        select_columns_result = select_columns.join(", ")
        result = @db.execute("SELECT #{select_columns_result} FROM #{from_table} WHERE #{compare_column}=?", [value])
        return result
    end

    def insert_into(insert_table, columns, values)
        querys = "?, " * values.size
        querys = querys[0...-2]
        @db.execute("INSERT INTO #{insert_table} (#{columns.join(", ")}) VALUES (#{querys})", values)
    end
end

module Users
    def self.login(username, password)
        db = SQL.new

        result = db.select(["id", "password_digest"], "users", "name", username).first

		if result.nil?
			return nil		
		end

		user_id = result["id"]
		password_digest = result["password_digest"]
		if BCrypt::Password.new(password_digest) == password
			return {user_id:user_id, username:username}
		else
			return nil
        end
    end

    def self.register(username, password, password_confirmation)
        db = SQL.new
        
        result = db.select(["*"], "users", "name", username)
		
		if result.empty?
			if password == password_confirmation
				password_digest = BCrypt::Password.create(password)
                db.insert_into("users", ["name", "password_digest"], [username, password_digest])
				return 0
			else
				return 1000
			end
		else
			return 1001
		end
    end
end