Rails.application.routes.draw do

  root 'projects#index'

  get "projects/:project_id/interpret_task" => "projects#interpret_task", as:  :project_interpret_task
  post 'projects/:project_id/update_status' => 'projects#update_status', as:  :project_update_status
  get "projects/:project_id/read_logs" => "projects#read_logs", as:  :project_read_logs
  get "projects/:project_id/check_project_status" => "projects#check_project_status", as:  :project_check_project_status
  get "projects/:project_id/update_loadtest_results" => "projects#update_loadtest_results", as:  :project_update_loadtest_results
  get "projects/:project_id/check_download_status" => "projects#check_download_status", as:  :project_check_download_status
  post 'projects/:project_id/job_error' => 'projects#job_error', as: :project_job_error

  resources :projects, :except => [:edit, :update] do
    resources :clusters
    resources :data_centers, :controller => "clusters", :type => "DataCenter"
    resources :amazon_clouds, :controller => "clusters", :type => "AmazonCloud"
  	resources :test_plans
    resources :target_hosts
    resources :load_tests
    resources :generated_reports, :only => [:index, :show, :destroy]
  end

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
