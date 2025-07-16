class EditsController < ApplicationController
    before_action :get_sentence, only: [:save_modified_clone, :index, :show, :new, :create, :edit, :update, :destroy]
    before_action :set_edit, only: [:save_modified_clone, :show, :edit, :update, :destroy]
  
    # GET /edits
    # GET /edits.json
    def index
      require_admin
  
      #@edits = Edit.all
      # @edits = @sentence.edits
      @edits = @sentence.edits.order('created_at')
    end
  
    # GET /edits/1
    # GET /edits/1.json
    def show
      require_admin
    end
  
    # GET /edits/new
    def new
      require_admin
      @edit = Edit.new
    end
  
    # GET /edits/1/edit
    def edit
      require_admin
    end
  
    # POST /edits
    # POST /edits.json
    def create
      require_admin
      #@edit = Edit.new(edit_params)
      @edit = @sentence.edits.new(edit_params)
      if @edit.save
        flash[:success] = 'Edit was successfully created.'
        redirect_to sentence_edit_path(@sentence, @edit)
      else
        render :new
      end
    end
  
    # PATCH/PUT /edits/1
    # PATCH/PUT /edits/1.json
    def update
      require_admin
      # byebug
      if @edit.update(edit_params)
        flash[:success] = 'Edit was successfully updated.'
        respond_to do |format|
          format.html { redirect_to sentence_edit_path(@sentence, @edit) }
          format.json { render json: @edit }
          # format.json { respond_with_bip(@edit) }
          # format.js
        end
      else
        render :edit
      end
    end
  
    def save_modified_clone
      if params[:commit] == 'Cancel'
        #redirect_to :back and return #don't, else the timers are not reset
        redirect_to translation_sentence_path(@sentence.translation, @sentence) and return
      end 
  
      #if params['content'].strip == @edit.content.strip #has to strip both sides in case of edit ending in '... '
      if params['content'] == @edit.content #allows for removing trailing space
        flash[:danger] = "You did not change anything. Not saved."
        redirect_to translation_sentence_path(@sentence.translation, @sentence) and return
      end 
  
      if params['content'].strip.empty? #saving of empty string not allowed, else can't get it editable again
        flash[:danger] = "Empty strings not allowed. Not saved."
        redirect_to translation_sentence_path(@sentence.translation, @sentence) and return
      end 
  
      #puts "@edit.id: #{@edit.id}"
      #puts "@edit.content: #{@edit.content}"
      #puts "base: #{params[:base]}"
  
      new_edit = @edit.dup
      new_edit.content = params['content']
      #new_edit.content = new_edit.content.gsub!(/\n/, "")
      new_edit.content = new_edit.content.squish #remove surrounding white space and embedded newlines
      #puts "new_edit.content: #{new_edit.content}"
      new_edit.save
  
      create_contribution = Contribution.new(kind: "C", effort_in_seconds: stop_create_timer)
      create_contribution.edit = new_edit 
  
      create_contribution.base_edit = @edit 
      create_contribution.base = params[:base] 
  
      create_contribution.assignment = current_user.cur_assign
      create_contribution.save
  
      #determine if a vote contribution already exists for this sentence
      te = top_edit(@sentence)
      vote_contributions = Contribution.joins(edit: :sentence).joins(:assignment).where(sentences: {id: @sentence.id}, contributions: {kind: 'V', assignment_id: current_user.cur_assign.id})
      #decide based on number of vote contributions found
      if(vote_contributions.length == 0)
        #Contribution.create(kind: 'V', assignment: current_user.cur_assign, edit: new_edit)
        Contribution.create(kind: 'V', assignment: current_user.cur_assign, edit: new_edit, base_edit: te, base: 'c')
        #flash[:success] = "Created vote contribution for edit #{new_edit.id}" 
      elsif(vote_contributions.length == 1)
        vote_contribution = vote_contributions.first
        #vote_contribution.update(edit: new_edit)
        vote_contribution.update(edit: new_edit, base_edit: te, base: 'c')
        #flash[:success] = "Pointed vote contribution to edit #{new_edit.id}" 
      else
        flash[:danger] = "More than 1 vote contributions found. Did not perform the vote. First fix the data for sentence #{@edit.sentence.id}"
      end
  
      # recalc the top edit
      recalc_top_edit
  
      # increment mods: each time an edit is used as the basis for modification, its mods is incremented
      current_mods = @edit.mods 
      @edit.update(mods: current_mods + 1)
  
      if(session[:auto_advance_after_save]) 
        auto_advance_to_next_sentence()
      end
  
      #redirect_to :back #don't, else the timers are not reset
      redirect_to translation_sentence_path(@sentence.translation, @sentence) 
    end
  
    # DELETE /edits/1
    # DELETE /edits/1.json
    def destroy
      @edit.contributions.destroy_all
      @edit.destroy
      #flash[:danger] = 'Edit was successfully destroyed'
     
      # recalc the top edit
      recalc_top_edit
  
      #redirect_to :back #don't, else the timers are not reset
      redirect_to translation_sentence_path(@sentence.translation, @sentence) 
    end
  
    def vote
      #determine if a vote contribution already exists for this sentence
      get_sentence
      set_edit
      te = top_edit(@sentence)
      vote_contributions = Contribution.joins(edit: :sentence).joins(:assignment).where(sentences: {id: @sentence.id}, contributions: {kind: 'V', assignment_id: current_user.cur_assign.id})
  
      #decide based on number of vote contributions found
      if(vote_contributions.length == 0)
        #Contribution.create(kind: 'V', assignment: current_user.cur_assign, edit: @edit, effort_in_seconds: stop_vote_timer)
        Contribution.create(kind: 'V', assignment: current_user.cur_assign, edit: @edit, effort_in_seconds: stop_vote_timer, base_edit: te, base: base_for_vote_contribution(te, @edit))
        #flash[:success] = "Created vote contribution for edit #{@edit.id}" 
      elsif(vote_contributions.length == 1)
        vote_contribution = vote_contributions.first
        new_effort = vote_contribution.effort_in_seconds + stop_vote_timer
        #vote_contribution.update(edit: @edit, effort_in_seconds: new_effort)
        vote_contribution.update(edit: @edit, effort_in_seconds: new_effort, base_edit: te, base: base_for_vote_contribution(te, @edit))
        #flash[:success] = "Pointed vote contribution to edit #{@edit.id}" 
      else
        flash[:danger] = "More than 1 vote contributions found. Did not perform the vote. First fix the data for sentence #{@sentence.id}"
      end
  #byebug
      
      # recalc the top edit
      recalc_top_edit
  
      if(session[:auto_advance_after_vote]) 
        auto_advance_to_next_sentence()
      end
  
      #redirect_to :back #don't, else the timers are not reset
      redirect_to translation_sentence_path(@sentence.translation, @sentence) 
    end
  
    # move the following 4 handlers to devise's sessions/users controller in the future?
    def enable_auto_advance_after_vote()
      session[:auto_advance_after_vote] = true
      flash[:danger] = 'Auto-advance after VOTE is now ENABLED. When you click the Vote button, the system will automatically advance to the next sentence. Click on the Profile menu item to disable this option again.'
      redirect_back fallback_location: root_path
    end
  
    def disable_auto_advance_after_vote()
      session[:auto_advance_after_vote] = false
      flash[:danger] = 'Auto-advance after VOTE is now DISABLED. When you click the Vote button, the system will remain at the current sentence. Click on the Profile menu item to enable this option again.'
      redirect_back fallback_location: root_path
    end
  
    def enable_auto_advance_after_save()
      session[:auto_advance_after_save] = true
      flash[:danger] = 'Auto-advance after SAVE is now ENABLED. When you click the Save button, the system will automatically advance to the next sentence. Click on the Profile menu item to disable this option again.'
      redirect_back fallback_location: root_path
    end
  
    def disable_auto_advance_after_save()
      session[:auto_advance_after_save] = false
      flash[:danger] = 'Auto-advance after SAVE is now DISABLED. When you click the Save button, the system will remain at the current sentence. Click on the Profile menu item to enable this option again.'
      redirect_back fallback_location: root_path
    end
  
    def auto_advance_to_next_sentence()
      next_rsen = @sentence.rsen + 1
      if next_rsen > @sentence.translation.senc
        next_rsen = @sentence.translation.senc 
        flash[:danger] = 'This is the last sentence.'
      end
      current_user.cur_assign.update(place: next_rsen)
      @sentence = @sentence.translation.sentences.where(rsen: next_rsen).first
    end
  
    def recalc_top_edit
      # find top_edit_candidates
      max_vote_count = 0 
      top_edit_candidates = []
      @sentence.edits.each do |e|
        cur_vote_count = e.vote_count
        cur_id = e.id
        #puts "************* cur_vote_count: #{cur_vote_count}"
        #puts "************* cur_id: #{cur_id}"
        if cur_vote_count >= max_vote_count
          if cur_vote_count == max_vote_count
            top_edit_candidates << e
          else # >
            max_vote_count = cur_vote_count
            top_edit_candidates = []
            top_edit_candidates << e
          end
        end
      end
      #puts "!!!!!!! top_edit_candidates:"
      #top_edit_candidates.each { |e1| puts e1.id }
  
      # find top edit
      if top_edit_candidates.length == 0
        flash[:danger] = 'ERROR: There should always be at least one top edit !!!'
        #redirect_to :back #don't, else the timers are not reset
        redirect_to translation_sentence_path(@sentence.translation, @sentence) 
      elsif top_edit_candidates.length == 1 # single top_edit_candidate
        top_edit = top_edit_candidates[0]
        if top_edit.contributions.where(kind: 'V').length == 0 #Zero-vote top edit
          top = 'Z'
        else
          top = 'M' #Majority top edit
        end
      else # multiple top_edit_candidates, take the one with highest primary key
        #max_id = 0
        max_created_at = Date.new(0) 
        top_edit_candidates.each do |tec|
          #if tec.id > max_id
          if tec.created_at > max_created_at
            #max_id = tec.id
            max_created_at = tec.created_at
          end
        end
        ##top_edit = Edit.find(max_id)
        #top_edit = @sentence.edits.where(id: max_id).first
        top_edit = @sentence.edits.where(created_at: max_created_at).first
        if top_edit.contributions.where(kind: 'V').length == 0 #Zero-vote top edit
          top = 'Z'
        else
          top = 'T' #tie top edit
        end
      end
      #puts "!!!!!!!!!!!!!!!!!! top_edit: #{top_edit.id}"
      
      # set top edit
      @sentence.edits.each { |e5| e5.update(top: 'N') } #not top edit
      #@sentence.edits.where(id: top_edit.id).first.update(top: true)
      @sentence.edits.where(created_at: top_edit.created_at).first.update(top: top)
      #puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! edits:"
      get_sentence
      #@sentence.edits.each { |e| puts "#{e.id} #{e.created_at} #{e.top}" }
    end
  
    def top_edit(sentence)
      te = sentence.edits.where(top: ['M', 'T', 'Z']).first
      #puts "THIS IS THE TOP EDIT: #{te}"
      te
    end
  
    def base_for_vote_contribution(top_edit, edit_voted_for) 
      if( edit_voted_for.contributions.where(kind: 'T').length > 0 ) #top_edit provided by a translator
        'a' #accepting
      elsif( top_edit.id == edit_voted_for.id ) #user voted for the current top edit
        't' #topping
      else
        'p' #picking (another edit)
      end
    end
  
    private
      def get_sentence
        @sentence = Sentence.find(params[:sentence_id])
      end 
  
      # Use callbacks to share common setup or constraints between actions.
      def set_edit
        #@edit = Edit.find(params[:id])
        @edit = @sentence.edits.find(params[:id])
      end
  
      # Never trust parameters from the scary internet, only allow the white list through.
      def edit_params
        params.require(:edit).permit(:content, :hid, :top, :sentence_id, :base)
      end
  
      def require_admin
        if !user_signed_in? || (user_signed_in? and !current_user.admin?)
          flash[:danger] = 'Only admins can perform that action'
          redirect_to root_path
        end
      end
      
  end