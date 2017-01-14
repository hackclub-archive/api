module V1
  class Cloud9Controller < ApplicationController
    def send_invite
      invite = Cloud9Invite.new(email: email)

      if invite.save
        render json: { success: true }
      else
        render json: { errors: invite.errors }, status: 422
      end
    end

    protected

    def email
      params[:email]
    end
  end
end
