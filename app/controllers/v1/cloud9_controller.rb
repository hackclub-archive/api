module V1
  class Cloud9Controller < ApplicationController
    def send_invite
      invite = Cloud9Invite.new(email: email)
      unless invite.valid?
        return render json: { errors: invite.errors }, status: 422
      end

      invite.save

      render json: { success: true }
    end

    protected

    def email
      params[:email]
    end
  end
end
