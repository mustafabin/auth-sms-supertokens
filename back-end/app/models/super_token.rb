class SuperToken < ApplicationRecord
    validates_uniqueness_of :token
    belongs_to :user
    # if no limit is desired then set const to 0
    # avoid changing this number but if changed all tokens prior to change will be deleted ordered by usage (the most active token stays)
    LIMIT_TOKENS_PER_USER = 2 # MINIMUN IS 2!!! sms tokens take 1 slot 
    AUTO_REFRESH = true
    DAYS_TO_EXPIRE = 14
    SMS_EXPIRY = 10 # in minutes 

    def self.generate_token(user,request, sms=false)
        if user && request
            all_tokens = SuperToken.where(user_id: user.id)
            # if there is a limit destroy the least active token(s)
            if LIMIT_TOKENS_PER_USER != 0 && all_tokens.length >= LIMIT_TOKENS_PER_USER
                if all_tokens.length > LIMIT_TOKENS_PER_USER # this line should only happen in the event the const LIMIT changes
                    # Because the amount of active tokens exceeds the limit
                    # All of oldest tokens up to the limit must be deleted 
                    # This happens when the const LIMIT_TOKENS_PER_USER is changed from last start up
                    # Due to the limit being variable we must order the tokens first and grab the latest valid time 
                    # and deleting all the tokens older than the oldest valid token (the younger the token the most recently it has been used)
                    last_valid_time = all_tokens.order("updated_at DESC").slice(0,LIMIT_TOKENS_PER_USER-1).last.updated_at
                    all_tokens.where("updated_at < ?", last_valid_time).destroy_all
                else
                    all_tokens.order("updated_at")[0].destroy #Destroy old token
                end
            end
            if(!sms)
                # generate hash https://github.com/rails/rails/blob/main/activerecord/lib/active_record/secure_token.rb
                hash = SecureRandom.base58(36)
                # generate token based off user
                SuperToken.create!(token:hash, user_id: user.id, client_ip: request.remote_ip, agent: request.user_agent, expiry: Time.now)
            else
                SuperToken.where(user_id:user.id).where(is_sms:true).destroy_all #Destroys all the old sms tokens to create a new one
                randomNumber = rand(12345..99999)
                SuperToken.create!(token:"#{user.id}#{randomNumber}",is_sms:true, user_id: user.id, client_ip: request.remote_ip, agent: request.user_agent, expiry: Time.now)
            end
        else 
            raise "user and/or request arguments undefined"
        end
    end
    def self.vaildate_super request
        token = request.headers["SuperToken"]
        if !token
            return {status: "bad", error:"SuperToken Not Header Found", message:"Header needs to called SuperToken not anything else"}
        end
        super_token = SuperToken.find_by(token:token)
        if !super_token
            return {status: "bad", error:"SuperToken Incorrect", message:"Token doesnt exist in database"}
        end
        if super_token.is_sms
            age_of_token = Time.now.to_i - super_token.created_at.to_i 
            user = super_token.user
            super_token.destroy
            if(age_of_token < SMS_EXPIRY*60)
                user.update(is_verified: true)
                return {status: "ok", user:user}
            else
                return {status: "bad", error:"401 not authorized", message:"EXPIRED SMS TOKEN"}
            end
        end
        if super_token.client_ip == request.remote_ip
            if is_expired super_token.expiry.to_i
                super_token.destroy 
                {status: "bad", error:"401 not authorized", message:"EXPIRED TOKEN"}
            else
                if AUTO_REFRESH 
                    super_token.update(expiry: Time.now)
                else
                    super_token.update(updated_at: Time.now)
                end
                 {status: "ok", user:super_token.user}
            end
        else
            {status: "bad", error:"403 forbidden", message:"DIFFERENT DEVICE "}
        end
    end


    def self.expiry_time
        86400 * DAYS_TO_EXPIRE
    end

    def self.is_expired time
        age = Time.now.to_i - time
        expiry_time < age ? true : false
    end

end
