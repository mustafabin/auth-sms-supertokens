class UsersController < ApplicationController
    before_action :authorize, only: [:me]

    def all
        users = User.all
        render json: users
    end
    def signup
        # create user from params 
        user = User.create!(email: params[:email], password: params[:password], phone: params[:phone])
        token = SuperToken.generate_token(user, request)
        render json: {user:user, token: token}
    end
    def login
        user = User.find_by!(email:params[:email]).try(:authenticate, params[:password])
        if user
            token = SuperToken.generate_token(user, request)
            render json: {user:user, token: token}
        else
            render json: {message: "Incorrect password"}
        end
    end
    def me
        render json: @user
    end
end
