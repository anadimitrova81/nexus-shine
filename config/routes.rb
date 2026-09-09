Rails.application.routes.draw do
  # Reveal health status on /up for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get  "about",   to: "pages#about",        as: :about
  get  "contact", to: "pages#contact",      as: :contact
  post "contact", to: "pages#send_message"
  get  "faq",     to: "pages#faq",          as: :faq
  get  "privacy", to: "pages#privacy",      as: :privacy

  # Shop: /shop (all), /shop?category=carwash, product at /product/:slug
  get "shop",         to: "products#index", as: :shop
  get "product/:id",  to: "products#show",  as: :product

  # Session cart
  get    "cart",                 to: "carts#show",   as: :cart
  post   "cart/add/:product_id", to: "carts#add",    as: :cart_add
  patch  "cart/:product_id",     to: "carts#update", as: :cart_update
  delete "cart/:product_id",     to: "carts#remove", as: :cart_remove
  delete "cart",                 to: "carts#clear",  as: :cart_clear

  # Invoice ЕИК autofill (JSON, used on the checkout page)
  resources :eik_lookups, only: %i[show]

  # Speedy shipping calculator (JSON, used on the checkout page)
  get "shipping/sites",   to: "shipping#sites"
  get "shipping/offices", to: "shipping#offices"
  get "shipping/quote",   to: "shipping#quote"

  # Checkout → creates an Order
  resources :orders, only: %i[new create show] do
    get :proforma, on: :member
  end

  # myPOS card payment flow
  # myPOS returns the customer to URL_OK / URL_Cancel with a POST (the local
  # simulator uses GET), so both verbs are accepted on the return routes.
  get   "orders/:id/pay",             to: "payments#new",     as: :pay_order
  match "orders/:id/payment/success", to: "payments#success", as: :order_payment_success, via: %i[get post]
  match "orders/:id/payment/cancel",  to: "payments#cancel",  as: :order_payment_cancel,  via: %i[get post]
  post  "orders/:id/payment/notify",  to: "payments#notify",  as: :order_payment_notify

  # Local myPOS simulator (development only).
  if Rails.env.development?
    post "dev/mypos/checkout", to: "dev/mypos#checkout"
    post "dev/mypos/pay",      to: "dev/mypos#pay"
    post "dev/mypos/cancel",   to: "dev/mypos#cancel"
  end

  # Admin back office (password-gated).
  namespace :admin do
    root to: "dashboard#show"
    get    "login",  to: "sessions#new",     as: :login
    post   "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout

    # Change the admin password (logged in) / set it via a console-issued link.
    resource  :password,        only: %i[edit update],  controller: "passwords"
    resources :password_resets, only: %i[create show update], param: :token

    resources :categories
    resources :brands
    resources :products
    resources :orders, only: %i[index show update] do
      member do
        get :invoice
        post :issue_invoice
      end
    end
  end
end
