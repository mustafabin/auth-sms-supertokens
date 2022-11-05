class UsersController < ApplicationController
    before_action :authorize, only: [:me,:verify_sms]
    
    rescue_from Twilio::REST::RestError, with: :twilio_error

    def all
        users = User.all
        render json: users
    end
    def signup
        # create user from params 
        user = User.create!(email: params[:email], password: params[:password], phone: params[:phone])
        supertoken = SuperToken.generate_token(user, request)
        render json: {user:user, token: supertoken.token}
    end
    def login
        user = User.find_by!(email:params[:email]).try(:authenticate, params[:password])
        if user
            supertoken = SuperToken.generate_token(user, request)
            render json: {user:user, token: supertoken.token}
        else
            render json: {message: "Incorrect password"}
        end
    end
    def me
        render json: @user
    end
    def text
        user = User.find_by!(email: params[:email])
        token = SuperToken.generate_token(user, request,true)
        account_sid = ENV['TWILIOACCOUNTSID']
        auth_token = ENV['TWILIOAUTHTOKEN']
        client = Twilio::REST::Client.new(account_sid, auth_token)
        
        from = '+18316182686' # Your Twilio number
        to = "+1#{user.phone}" # Your mobile phone number

        client.messages.create(
            from: from,
            to: to,
            body: "Hello there your verifcation code is: #{token.token}"
        )

        render json: {status:"good",message: "sent"}
    end
    def verify_sms
        render json:  @user
    end
    private
    def twilio_error(exception)
        render json: { status: "bad",error: exception.error_message }, status: 400 
    end
end
