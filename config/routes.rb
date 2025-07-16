Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", sessions: "sessions" }
  match 'users/:id' => 'users#destroy', :via => :delete, :as => :admin_destroy_user
  resources :users

  get '/enable_auto_advance_after_vote', to: 'edits#enable_auto_advance_after_vote'
  get '/disable_auto_advance_after_vote', to: 'edits#disable_auto_advance_after_vote'
  get '/enable_auto_advance_after_save', to: 'edits#enable_auto_advance_after_save'
  get '/disable_auto_advance_after_save', to: 'edits#disable_auto_advance_after_save'

  root 'pages#home'

  get '/help', to: 'pages#help'
  get '/about', to: 'pages#about'
  get '/timeout', to: 'pages#timeout'

  resources :messages do
    resources :translations
  end
  get '/all_translations', to: 'translations#all_translations'

  resources :translations do
    resources :sentences
    member do
      get :import_lookup_form
      post :import_lookup
      get :randomize_translate_contributions
    end
  end
  get '/destroy_sentences', to: 'translations#destroy_sentences'
  get '/destroy_lookups', to: 'translations#destroy_lookups'

  resources :lookups

  resources :sentences do
    resources :edits do
      member do
        post :vote
      end
    end
    member do
      get :next
      get :prev
      get :increase_context
      get :decrease_context
      get :timeout
      get :multi_button_action
      get :show_search
      get :show_preview
    end
  end
  #get '/translations/:translation_id/sentences/:id/next', :to => 'sentences#next', as: 'next_sentence'
  #get '/translations/:translation_id/sentences/:id/prev', :to => 'sentences#prev', as: 'prev_sentence'

  #get '/signup', to: 'users#new'
  # get '/signup', to: 'users#signup'
  #resources :users, except: [:new]
  # resources :users
  
  #resources :assignments 
  #get '/assignments/:id/import_content_form', :to => 'assignments#import_content_form'
  #post '/assignments/:id/import_content', :to => 'assignments#import_content'
  resources :assignments do
    member do
      get :import_content_form
      post :import_content
      get :validate_content_form
      post :validate_content
      get :report
    end
  end
  get '/destroy_contributions', to: 'assignments#destroy_contributions'
  get '/status_assignments', to: 'assignments#status_assignments'
  get '/status_assignments_seven_day', to: 'assignments#status_assignments_seven_day'
  get '/status_assignments_all_time_work', to: 'assignments#status_assignments_all_time_work'
  get '/status_assignments_all_time_translations', to: 'assignments#status_assignments_all_time_translations'
  get '/team_assignments', to: 'assignments#team_assignments'

  resources :contributions

  #get 'login', to: 'sessions#new'
  #post 'login', to: 'sessions#create'
  #delete 'logout', to: 'sessions#destroy'

  post '/sentences/:sentence_id/edits/:id/save_modified_clone', :to => 'edits#save_modified_clone'

  get '/users/:id/assignments/:id/switch', to: 'users#switch_current_assignment'
  #get 'users/switch_current_assignment/:id/:assignment_id'

  resources :text_exports, :only => [:new, :create]
  #get 'text_exports/success' => 'text_exports#success', as: :success

  resources :dash_exports, :only => [:new, :create]
  #get 'dash_exports/success' => 'dash_exports#success', as: :success
  #get 'dash_exports/download' => 'dash_exports#download', as: :download



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end