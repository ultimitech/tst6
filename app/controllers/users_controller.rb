class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :switch_current_assignment]
  #before_action :require_same_user, only: [:edit, :update] #TODO: put back!
  #before_action :require_admin

  # GET /users
  # GET /users.json
  def index
    # require_admin
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    require_admin
  end

  # GET /users/new
  def new
    require_admin
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    require_admin
  end

  # POST /users
# POST /users.json
  #todo: if a visitor clicks 'Help us proofread', the user should be created
  #with confirmed=false, else, if the admin creates a new user, with confirmed=true
  def create
    require_admin
    # debugger
    @user = User.new(user_params)

    if @user.save
      flash[:success] = "User was successfully created"
      redirect_to user_path(@user)
    else
      render 'new'
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    require_admin
    if @user.update(user_params)
      flash[:success] = "User was successfully updated"
      redirect_to user_path(@user)
    else
      render 'edit'
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    require_admin
    @user = User.find(params[:id])

    #test if this user is still pointed to by an assignment
    if Assignment.all.where(user_id: @user.id).count > 0
      flash[:danger] = "ERROR: Cannot destroy user: #{@user.id}. It has other assignments pointing to it!"
      redirect_to users_path and return
    else 
      @user.destroy  
      flash[:danger] = "User was successfully deleted"
      redirect_to users_path
    end
  end

  def switch_current_assignment
    assignment = Assignment.find(params[:assignment_id])
    @user.cur_assign = assignment
    if @user.save
      flash[:success] = "Assignment was successfully switched"
      if Assignment.admin_roles.include? @user.cur_assign.role
        redirect_to assignment_path(assignment) 
      else
        translation = @user.cur_assign.translation
	sentence = translation.sentences.where(rsen: @user.cur_assign.place).first
        redirect_to translation_sentence_path(translation, sentence)
      end
    else
      flash[:danger] = "Assignment was NOT switched"
      redirect_to :back 
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :username, :password, :admin, :assignment_id, :cur_assign_id)
    end

    def require_same_user
      if current_user != @user
        flash[:danger] = 'You can only edit your own account'
        redirect_to root_path
      end
    end

    def require_admin
      if !user_signed_in? || (user_signed_in? and !current_user.admin?)
        flash[:danger] = 'Only admins can perform that action'
        redirect_to root_path
      end
    end

end