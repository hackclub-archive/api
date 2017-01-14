Rails.application.routes.draw do
  namespace :v1 do
    get 'ping', to: 'ping#ping'

    post 'leaders/intake'
    post 'cloud9/send_invite'

    resources :clubs

    namespace :hackbot do
      post 'auth', to: 'auth#create'
      post 'webhook', to: 'webhook#callback'
    end
  end
end
