class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy
  before_action :set_user, only: %i[index show create edit update destroy following followers]

  def index

    @users = User.paginate(page: params[:page])
    if params[:select] == "ユーザー検索"
      search_term = "%#{params[:data]}%"
      @users = @users.
                        where('name LIKE ?', search_term).
                        or(@users.where('email LIKE ?', search_term)).
                        or(@users.where('birthplace LIKE ?', search_term))
    elsif params[:select] == "キーワード検索"
      ##入力が空白だったら何もしない
      if params[:data] != ""
        search_term = "%#{User.sanitize_sql_like(params[:data])}%"
        @users = @users.where('introduction LIKE ?', search_term)
      end
    end
  end

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.where(deleted_flag: false).paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url, status: :see_other
  end

  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow', status: :unprocessable_entity
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow', status: :unprocessable_entity
  end
  def search
    @data = User.where(name: params[:data])
    redirect_to users_url data:params[:data],select: params[:select]
  end
  def show_likes 
    @user  = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])

  end
  private


  def user_params
    params.require(:user).permit(:name, :nickname, :email, :password,
                                 :password_confirmation, :birthplace, :introduction, :screen_mode)
  end

  # beforeフィルタ

  # 正しいユーザーかどうか確認
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url, status: :see_other) unless current_user?(@user)
  end

  # 管理者かどうか確認
  def admin_user
    redirect_to(root_url, status: :see_other) unless current_user.admin?
  end
  private

  def set_user
    if current_user
      @new_micropost = current_user.feed.where("created_at >= ?", Settings.about.new.time.hours.ago).count
      @new_micropost = current_user.feed.where("created_at >= ?", Settings.about.new.time.hours.ago).limit(Settings.about.new.num)
      @new_microposts_count = @new_micropost.count
    end
  end
end
