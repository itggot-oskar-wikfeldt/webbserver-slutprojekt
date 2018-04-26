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
        columns_result = columns.join(", ")
        result = @db.execute("INSERT INTO #{insert_table} (#{columns_result}) VALUES (?,?)", values)
        return result
    end
end

module Users
    def self.login(username, password)
        db = SQL.new

        result = db.select(["id", "password_digest"], "users", "name", username)

		if result.empty?
			return nil		
		end

		user_id = result.first["id"]
		password_digest = result.first["password_digest"]
		if BCrypt::Password.new(password_digest) == password
			return {user_id:user_id, username:username}
		else
			return nil
        end
    end

    def self.register(username, password, password_confirmation)
        db = SQL.new
        
        result = db.select(["id"], "users", "name", username)
		
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