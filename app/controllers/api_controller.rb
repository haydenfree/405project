class ApiController < ActionController::API
    # Hayden Free
    # Cole Terrell

    # =============================
    #     Helper Functions
    # =============================

    def connect
        client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "ZoeqxUDQbBxuHA7mGX7p", :database => "SMPDB")
        return client
    end

    # authenticates the handle + password combination, and if is valid returns the idnum of that user
    def authenticate(handle, password)
        client = connect()
        results = client.query("SELECT idnum FROM Identity i WHERE (i.handle = \"#{handle}\") AND (i.pass = \"#{password}\")")
        if results.count == 1
            return results.first["idnum"]
        else
            return false
        end
    end
    
    def is_blocked(this_user_id, other_user_id)
        client = connect()
        # queries if this_user (the user submitting to the API) is blocked by other_user
        results = client.query("select 1 from Identity as a inner join Block as b on (a.idnum = b.blocked) where a.idnum = #{this_user_id} and b.idnum = #{other_user_id};")
        # if empty set is returned then this_user is not blocked by other_user
        if results.count == 0
            return false;
        else 
            return true;
        end
    end

    def get_idnum_from_storyid(storyid)
        client = connect()
        results = client.query("select idnum from Story where sidnum = #{storyid}")
        if results.count == 0
            return false
        else
            return results.first["idnum"]
        end
    end

    # =============================
    #    API Route Handlers
    # =============================

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
                render json:{"status":"0", "error":"#{exception}"}.to_json
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
                render json:{"status":"0", "error":"#{exception}"}.to_json
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
                    results = client.query("insert into Story (idnum, chapter, url, expires) select a.idnum, \"#{params[:chapter]}\", \"#{params[:url]}\", \"#{params[:expires]}\" from Identity as a where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\";")
                else
                    # story doesn't expire
                    results = client.query("insert into Story (idnum, chapter, url) select a.idnum, \"#{params[:chapter]}\", \"#{params[:url]}\" from Identity as a where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\";")
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
        # authenticate returns idnum if handle+password combination works, so store it
        if ( this_user_id = authenticate(params[:handle], params[:password]) )
            # get the id of the user that owns the story attempting to be reprinted
            # if get_idnum_from_storyid returns false it means the story could not be found, handle that here
            if ( story_owners_id = get_idnum_from_storyid(params[:storyid]) )
                # check if the user trying to reprint is blocked by user that owns the story
                if (is_blocked(this_user_id, story_owners_id))
                    render json:{"status":"0", "error":"blocked"}.to_json
                # otherwise attempt to reprint
                else
                    # user auth worked and user is not blocked - create connection for query
                    client = connect()
                    begin
                        # if likeit is omitted then it defaults to false
                        if params[:likeit].nil?
                            params[:likeit] = false
                        end
                        # run query
                        results = client.query("insert into Reprint (idnum, sidnum, likeit) select a.idnum, #{params[:storyid]}, #{params[:likeit]} from Identity as a where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\";")
                    rescue => exception
                        render json:{"status":"0", "error":"#{exception}"}.to_json
                    else
                        # return status 1 to indicate success
                        render json: {"status":"1"}.to_json, status: :ok
                    end
                end
            else
                render json:{"status":"0", "error":"story not found"}.to_json
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def follow
        # authenticate returns idnum if handle+password combination works, so store it
        if ( this_user_id = authenticate(params[:handle], params[:password]) )
            # check if the user trying to follow is blocked by user
            if (is_blocked(this_user_id, params[:userid]))
                render json:{"status":"0", "error":"blocked"}.to_json
            else
                # user auth worked and user is not blocked - create connection for query
                client = connect()
                begin
                    # run query
                    results = client.query("insert into Follows (follower, followed) select a.idnum, #{params[:userid]} from Identity as a where (a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\") and not (exists (select x.followed from Identity as y inner join Follows as x on (y.idnum = x.follower and y.handle = \"#{params[:handle]}\" and x.followed = #{params[:userid]})));")
                rescue => exception
                    render json:{"status":"0", "error":"#{exception}"}.to_json
                else
                    # return status 1 to indicate success
                    render json: {"status":"1"}.to_json, status: :ok
                end
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def unfollow
        # authenticate returns idnum if handle+password combination works, so store it
        if (authenticate(params[:handle], params[:password]))
            # user auth worked - create connection for query
            client = connect()
            begin
                # run query
                results = client.query("delete from Follows where follower = (select a.idnum from Identity as a where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\") and followed = #{params[:userid]};")
            rescue => exception
                render json:{"status":"0", "error":"#{exception}"}.to_json
            else
                # return status 1 to indicate success
                render json: {"status":"1"}.to_json, status: :ok
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def block
        if (authenticate(params[:handle], params[:password]))
            # user auth worked - create connection for query
            client = connect()
            begin
                # run query
                results = client.query("insert into Block (idnum, blocked) select a.idnum, #{params[:userid]} from Identity as a where a.handle = \"#{params[:handle]}\" and a.pass = \"#{params[:password]}\" and not exists(select * from Identity as a inner join Block as b on (a.idnum = b.idnum and a.handle = \"#{params[:handle]}\" and b.blocked = #{params[:handle]}));")
            rescue => exception
                render json:{"status":"0", "error":"#{exception}"}.to_json
            else
                # return status 1 to indicate success
                render json: {"status":"1"}.to_json, status: :ok
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    def timeline
        if (authenticate(params[:handle], params[:password]))
            # user auth worked - create connection for query
            client = connect()
            begin
                # run query
                results = client.query("select \"story\" as type, zz.handle as author, c.sidnum, c.chapter as chapter, c.tstamp as posted from Identity as a inner join Follows as b on (a.idnum = b.follower) inner join Story as c on (b.followed = c.idnum)inner join Identity as zz on (c.idnum = zz.idnum) where a.handle = \"#{params[:handle]}\" and c.tstamp between \"#{params[:oldest]}\" and \"#{params[:newest]}\" and not exists((select 1 from Identity as xx inner join Block as qq on (xx.idnum = qq.blocked) where xx.handle = \"#{params[:handle]}\" and qq.idnum = c.idnum)) UNION select \"reprint\", pp.handle, y.sidnum, y.chapter, y.tstamp from Identity as q inner join Follows as x on (q.idnum = x.follower) inner join Reprint as t on (x.followed = t.idnum) inner join Story as y on (t.sidnum = y.sidnum) inner join Identity as pp on (y.idnum = pp.idnum)where q.handle = \"#{params[:handle]}\" and y.tstamp between \"#{params[:oldest]}\" and \"#{params[:newest]}\" and t.likeit is false and not exists((select 1 from Identity as x inner join Block as q on (x.idnum = q.blocked) where x.handle = \"#{params[:handle]}\" and q.idnum = y.idnum))order by posted desc;")
            rescue => exception
                render json:{"status":"0", "error":"#{exception}"}.to_json
            else
                data = {}
                current = 0
                results.each do |row|
                    current = current + 1
                    data[current] = {"type":"#{row["type"].to_s}", "author":"#{row["author"].to_s}", "sidnum":"#{row["sidnum"].to_s}", "chapter":"#{row["chapter"].to_s}", "posted":"#{row["posted"].to_s}" }
                end
                data["status"] = "#{results.count}"
                render json: data.to_json, status: :ok
            end
        else
            render json: {"status_code":"-10", "error":"invalid credentials"}.to_json
        end
    end

    
end