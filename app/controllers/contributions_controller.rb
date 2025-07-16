class ContributionsController < ApplicationController
    #before_filter :get_edit, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    #before_filter :get_assignment, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    before_action :set_contribution, only: [:show, :edit, :update, :destroy]
    before_action :require_admin
  
    # GET /contributions
    # GET /contributions.json
    def index
      @contributions = Contribution.all
    end
  
    # GET /contributions/1
    # GET /contributions/1.json
    def show
    end
  
    # GET /contributions/new
    def new
      @contribution = Contribution.new
    end
  
    # GET /contributions/1/edit
    def edit
    end
  
    # POST /contributions
    # POST /contributions.json
    def create
      @contribution = Contribution.new(contribution_params)
      if @contribution.save
        flash[:success] = 'Contribution was successfully created.'
        redirect_to contribution_path(@contribution)
      else
        render :new
      end
    end
  
    # PATCH/PUT /contributions/1
    # PATCH/PUT /contributions/1.json
    def update
      get_edit
      if @contribution.update(contribution_params)
        flash[:success] = 'Contribution was successfully updated.'
        redirect_to sentence_edit_path(@edit.sentence, @edit) 
      else
        render :edit
      end
    end
  
    # DELETE /contributions/1
    # DELETE /contributions/1.json
    def destroy
      @edit = Edit.find(@contribution.edit)
      @contribution.destroy
      flash[:danger] = 'Contribution was successfully destroyed.'
      redirect_to sentence_edit_path(@edit.sentence, @edit)
    end
  
    private
      def get_edit
        set_contribution
        @edit = Edit.find(@contribution.edit)
      end
  
      def get_assignment
        set_contribution
        @assignment = Assignment.find(@contribution.assignment)
      end
  
      # Use callbacks to share common setup or constraints between actions.
      def set_contribution
        @contribution = Contribution.find(params[:id])
      end
  
      # Never trust parameters from the scary internet, only allow the white list through.
      def contribution_params
        params.require(:contribution).permit(:kind, :effort_in_seconds, :edit_id, :assignment_id)
      end
  
      def require_admin
        if !user_signed_in? || (user_signed_in? and !current_user.admin?)
          flash[:danger] = 'Only admins can perform that action'
          redirect_to root_path
        end
      end
  
  end