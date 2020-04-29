class ApiController < ActionController::API
    
    def connect
        client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "ZoeqxUDQbBxuHA7mGX7p", :database => "SMPDB")
        return client
    end

    def authenticate(handle, password)
        client = connect()

        results = client.query("SELECT * FROM Identity i WHERE (i.handle = \"#{handle}\") AND (i.pass = \"#{password}\")")

        if results.count == 1
            return true
        else
            return false
        end
    end
    
    def createuser
        # create connection to db
        client = connect()
        
        begin
            # attempt to insert new user
            results = client.query("insert into Identity (handle, pass, fullname, location, email, bdate, joined) values (\"#{params[:handle]}\", \"#{params[:password]}\", \"#{params[:fullname]}\", \"#{params[:location]}\", \"#{params[:xmail]}\", \"#{params[:bdate]}\", \"#{Date.today.to_s}\");")            
        rescue => exception
            # catch and render error if there is one
            render json:{"status":"-2", "error":"#{exception}"}.to_json
        else
            # grab the id of the last inserted user
            id = client.query("SELECT LAST_INSERT_ID();")
            # return that id
            render json: {"status":"#{id.first["LAST_INSERT_ID()"]}"}.to_json, status: :ok
        end
    end

    def seeuser
        if authenticate(params[:handle], params[:password])
            render json: {handle: params[:handle], pass: params[:password]}.to_json, status: :ok
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json, status: :ok
        end        
    end

    def suggestions
        
    end

    def poststory
        
    end

    def reprint
        
    end

    def follow
        
    end

    def unfollow
        
    end

    def block
        
    end

    def timeline
        
    end

    
end
