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
            # create connection to db
            client = connect()
            begin
                # attempt to query user info
                results = client.query("select handle, fullname, location, email, bdate, joined from Identity where idnum = #{params[:userid]};")
            rescue => exception
                # catch and render error if there is one
                render json:{"status":"-2", "error":"#{exception}"}.to_json
            else
                # if one user was found return the data
                if results.count == 1
                    render json: {"status":"1", "handle":"#{results.first["handle"]}", "fullname":"#{results.first["fullname"]}", "location":"#{results.first["location"]}", 
                        "email":"#{results.first["email"]}", "bdate":"#{results.first["bdate"]}", "joined":"#{results.first["joined"]}"}.to_json, status: :ok
                # otherwise return an empty object
                else
                    render json: {}.to_json, status: :ok
                end
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def suggestions
        # authenticate user seeking suggestions
        if authenticate(params[:handle], params[:password])
            # user auth worked, create connection for query
            client = connect()
            begin
                # attempt to get suggestions
                results = client.query("select s.idnum, s.handle from Identity as a inner join Follows as b on (a.idnum = b.follower) inner join Follows as c on (b.followed = c.follower) inner join Identity as s on (c.followed = s.idnum) where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\" and s.handle != \"#{params[:handle]}\" and s.idnum not in (select x.followed from Identity as y inner join Follows as x on (y.idnum = x.follower and y.handle = \"#{params[:handle]}\")) LIMIT 4;")
            rescue => exception
                # catch and render error if there is one (there should not be any SQL errors here, but just in case)
                render json:{"status":"-2", "error":"#{exception}"}.to_json
            else
                # if there are no suggestions
                if results.count == 0
                    render json: {"status":"0", "error":"no suggestions"}.to_json
                else
                    # build the list of idnums and handles from the results
                    idnums = ""
                    handles = ""
                    results.each do |row|
                        # if this is the first id
                        if idnums.empty?
                            idnums << row["idnum"].to_s
                        else
                            idnums << "," << row["idnum"].to_s
                        end

                        if handles.empty?
                            handles << row["handle"].to_s
                        else
                            handles << "," << row["handle"].to_s
                        end
                    end
                    render json: {"status":"#{results.count}", "idnums":"#{idnums}", "handles":"#{handles}"}.to_json, status: :ok
                end
            end
        # authentication failed
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def poststory
        if authenticate(params[:handle], params[:password])
            # user auth worked, create connection for query
            client = connect()
            begin
                if params[:expires]
                    # handle expires param
                    results = client.query("insert into Story (idnum, chapter, url, expires) select a.idnum, \"#{params[:chapter]}\", \"#{params[:url]}\", \"#{params[:expires]}\" from Identity as a where a.handle = \"@snapoleon0\" and a.pass = \"xZmN6L\";")
                else
                    # story doesn't expire
                    results = client.query("insert into Story (idnum, chapter, url) select a.idnum, \"#{params[:chapter]}\", \"#{params[:url]}\" from Identity as a where a.handle = \"@snapoleon0\" and a.pass = \"xZmN6L\";")
                end
            rescue => exception
                # catch and render error if there is one
                render json:{"status":"0", "error":"#{exception}"}.to_json
            else
                # return status 1 to indicate success
                render json: {"status":"1"}.to_json, status: :ok
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
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