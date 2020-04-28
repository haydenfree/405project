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
        if authenticate(params[:handle], params[:password])
            render json: {handle: params[:handle], pass: params[:password]}.to_json, status: :ok
        else
            render json: {status: "-1", error: "Authentication failed"}.to_json, status: :ok
        end
    end

    def seeuser
        
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
