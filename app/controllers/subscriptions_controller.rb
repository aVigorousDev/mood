class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_by_session, only: [:create]

  def create
    @subscription = Subscription.find_or_create_by!(data: data) do |ps|
      ps.max_actions = max_actions
      ps.user = current_user if current_user.persisted?
    end

    render json: subscription, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: error.message, status: :bad_request
  end

  private

  def data
    subscription_params[:subscription]
  end

  def max_actions
    subscription_params[:max_actions]
  end

  def subscription_params
    params.permit(
      :max_actions,
      subscription: [
        :endpoint,
        :expirationTime,
        keys: [
          :auth,
          :p256dh,
        ],
      ],
    )
  end
end
