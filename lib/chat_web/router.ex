defmodule ChatWeb.Router do
  use ChatWeb, :router

  import ChatWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChatWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/avatars/:filename", PageController, :avatar
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChatWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:chat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ChatWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ChatWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ChatWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ChatWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/humans", HumanLive.Index, :index
      live "/humans/new", HumanLive.Index, :new
      live "/humans/:id/edit", HumanLive.Index, :edit

      live "/humans/:id", HumanLive.Show, :show
      live "/humans/:id/show/edit", HumanLive.Show, :edit

      live "/bot_models", BotModelLive.Index, :index
      live "/bot_models/new", BotModelLive.Index, :new
      live "/bot_models/:id/edit", BotModelLive.Index, :edit

      live "/bot_models/:id", BotModelLive.Show, :show
      live "/bot_models/:id/show/edit", BotModelLive.Show, :edit

      live "/personas", PersonaLive.Index, :index
      live "/personas/new", PersonaLive.Index, :new
      live "/personas/:id/edit", PersonaLive.Index, :edit

      live "/personas/:id", PersonaLive.Show, :show
      live "/personas/:id/show/edit", PersonaLive.Show, :edit

      live "/conversations", ConversationLive.Index, :index
      live "/conversations/new", ConversationLive.Index, :new
      live "/conversations/:id/edit", ConversationLive.Index, :edit

      live "/conversations/:id", ConversationLive.Show, :show
      live "/conversations/:id/show/edit", ConversationLive.Show, :edit

      live "/messages", MessageLive.Index, :index
      live "/messages/new", MessageLive.Index, :new
      live "/messages/:id/edit", MessageLive.Index, :edit

      live "/messages/:id", MessageLive.Show, :show
      live "/messages/:id/show/edit", MessageLive.Show, :edit

      live "/chat", ChatLive.Index, :index

      live "/chat/new", ChatLive.Index, :new

      live "/chat/:id", ChatLive.Index, :show
    end
  end

  scope "/", ChatWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ChatWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
