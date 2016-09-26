Rails.application.routes.draw do
  namespace :v1 do
    get 'ping', to: 'ping#ping'

    resources :clubs

    namespace :streak do
      resources :pipelines do
        collection do
          post 'sync'
        end
      end
    end
  end
end
