class SentencesController < ApplicationController
    before_action :get_translation, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    before_action :set_sentence, only: [:show, :edit, :update, :destroy]
    before_action :require_admin, only: [:index]
    before_action :require_sign_in
  
    ###helper_method :voted_for, :created, :top_edit_class
    ###helper_method :voted_for, :created
    helper_method :sentence_vote_contribution
    helper_method :sentence_vote_time
    helper_method :sentence_create_contributions
    helper_method :sentence_create_time
    #helper_method :vote_timer_status
    #helper_method :create_timer_status
  
    # GET /sentences
    # GET /sentences.json
    def index
      #@sentences = Sentence.all
      #@sentences = @translation.sentences
      @sentences = @translation.sentences.paginate(page: params[:page], per_page: 10)
    end
  
    def multi_button_action 
      #require_cur_assign
      if !current_user.cur_assign
        #flash[:danger] = 'You do not have an assignment currently'
        redirect_to root_path and return
      end
      @translation = Translation.find(params[:translation_id])
      if params["go_button"] # '>>'
        #puts "go_button was clicked ......................."
        go()
      elsif params["search_button"] # 'spyglass'
        #puts "search_button was clicked ......................."
        search()
      elsif params["place_button"] # '|^|' (bookmark)
        #puts "place_button was clicked ......................."
        place()
      elsif params["preview_button"] # 'eye'
        #puts "preview_button was clicked ......................."
        preview()
      else
        puts "ERROR: no option!!!!!!!"
      end
    end
  
    def go 
      # validate params (unless a param can be parsed to an integer, a nil is returned)
      # can't use standard way as for persisted models
      blk = Integer(params[:blk]) rescue nil
      rsub = Integer(params[:rsub]) rescue nil
      rsen = Integer(params[:rsen]) rescue nil
  
      # find destination sentence
      if blk #go to blk
        if not blk.between?(1, @translation.blkc)
          #flash[:danger] = "You attempted to go to block #{blk}. Blocks vary from 1 to #{@translation.blkc}."
          flash[:danger] = "You attempted to go to block #{blk}. This number is out of range."
          redirect_back(fallback_location: root_path) and return
        else
          sentence = @translation.sentences.where(blk: blk, sub: 1, sen: 1).first
        end
      elsif rsub #go to rsub
        if not rsub.between?(1, @translation.subc)
          #flash[:danger] = "You attempted to go to running subblock #{rsub}. Subblocks vary from 1 to #{@translation.subc}."
          flash[:danger] = "You attempted to go to running subblock #{rsub}. This number is out of range."
          redirect_back(fallback_location: root_path) and return
        else
          sentence = @translation.sentences.where(rsub: rsub, sen: 1).first
        end
      elsif rsen #go to rsen
        if not rsen.between?(1, @translation.senc)
          #flash[:danger] = "You attempted to go to running sentence #{rsen}. Running sentences vary from 1 to #{@translation.senc}."
          flash[:danger] = "You attempted to go to running sentence #{rsen}. This number is out of range."
          redirect_back(fallback_location: root_path) and return
        else
          sentence = @translation.sentences.where(rsen: rsen).first
        end
      else #no usable input
        if current_user.admin?
          flash[:danger] = "Input is invalid. You provided Blk=#{params[:blk]}, RSub=#{params[:rsub]}, RSen=#{params[:rsen]}. Please supply a valid number in one of the input fields."
        else
          flash[:danger] = "Input is invalid. Please supply a valid sentence number to jump to."
        end
        redirect_back(fallback_location: root_path) and return
      end
  
      # update user's place
      if sentence
        current_user.cur_assign.update(place: sentence.rsen)
      else
        flash[:danger] = 'No target sentence found.'
      end
  
      # update vote time
      #vote_contrib = vote_contribution(sentence)
      #vote_contrib.update(effort_in_seconds: vote_contrib.effort_in_seconds + stop_vote_timer) if vote_contrib
  
      redirect_to translation_sentence_path(@translation, sentence)
    end
  
    def search
      session[:search_term] = params[:search_term]
      redirect_to show_search_sentence_path()
    end
  
    def show_search 
      require_cur_assign
      @sentence = Sentence.find(params[:id])
      @translation = @sentence.translation
  
      if session["search_term"].blank? #no usable input
        flash[:danger] = "Input is blank. Please supply a valid search term."
        redirect_back(fallback_location: root_path) and return
      else 
        term = session[:search_term].downcase
  
        #escape any single quotes for sql queries, i.e. all ' becomes ''
        term = term.gsub("'", "''")
  
        #ENG query
        sql_eng = "select s.rsen, e.content 
  from edits as e
  join sentences as s on e.sentence_id=s.id
  join translations as t on s.translation_id=t.id
  where t.id=#{@translation.eng_tran.id} and lower(e.content) LIKE '%#{term}%' order by s.rsen;"
        search_hits = ActiveRecord::Base.connection.execute(sql_eng)
        @hits_eng = search_hits.values
        
        #OTH query for edits owned by user
        sql_oth_own = "select distinct s.rsen, e.content 
  from edits as e
  join contributions as c on c.edit_id=e.id
  join assignments as a on c.assignment_id=a.id
  join users as u on a.user_id=u.id
  join sentences as s on e.sentence_id=s.id
  join translations as t on s.translation_id=t.id
  where t.id=#{@translation.id} and u.id=#{current_user.id} and lower(e.content) LIKE '%#{term}%' order by s.rsen;"
        search_hits = ActiveRecord::Base.connection.execute(sql_oth_own)
        @hits_oth_own = search_hits.values
  
        #OTH query for edits NOT owned by user
        sql_oth_not = "select distinct s.rsen, e.content 
  from edits as e
  join contributions as c on c.edit_id=e.id
  join assignments as a on c.assignment_id=a.id
  join users as u on a.user_id=u.id
  join sentences as s on e.sentence_id=s.id
  join translations as t on s.translation_id=t.id
  where t.id=#{@translation.id} and not u.id=#{current_user.id} and lower(e.content) LIKE '%#{term}%' order by s.rsen;"
        search_hits = ActiveRecord::Base.connection.execute(sql_oth_not)
        @hits_oth_not = search_hits.values
      end 
    end
  
    def place
      rsen = current_user.cur_assign.place
      sentence = @translation.sentences.where(rsen: rsen).first
      redirect_to translation_sentence_path(@translation, sentence)
    end
  
    def preview
      puts @sentence
      redirect_to show_preview_sentence_path()
    end
  
    def show_preview
      require_cur_assign
      @sentence = Sentence.find(params[:id])
      @translation = @sentence.translation
  
      #ensure session has a preview value - gone if cur_assign has been set to nil for de-activation
      if not session[:preview]
        session[:preview] = 20
      end
      lo = @sentence.rsen - session[:preview]
      hi = @sentence.rsen
  
      sql_eng = "select s.rsub, s.sen, s.typ, s.rsen, e.content 
  from edits as e
  join sentences as s on e.sentence_id=s.id
  join translations as t on s.translation_id=t.id
  where t.id=#{@translation.eng_tran.id} and (s.rsen between #{lo} and #{hi}) order by s.rsen;"
      preview_E_edits = ActiveRecord::Base.connection.execute(sql_eng)
      @preview_E = format_preview(preview_E_edits)
  
      sql_oth = "select s.rsub, s.sen, s.typ, s.rsen, e.content 
  from edits as e
  join sentences as s on e.sentence_id=s.id
  join translations as t on s.translation_id=t.id
  where t.id=#{@translation.id} 
  and (s.rsen between #{lo} and #{hi}) 
  and not e.top='N' 
  order by s.rsen;"
      preview_O_edits = ActiveRecord::Base.connection.execute(sql_oth)
      @preview_O = format_preview(preview_O_edits)
    end
  
    def format_preview(preview_edits)
      preview = ''
      preview_edits.each do |e|
        if(['h', 'i', 'j'].include? e['typ'])
          preview << '<br/><br/>'
        elsif e['sen']==1
          preview << '<br/><br/>'
        elsif e['typ']=='s'
          preview << '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
        elsif e['typ']=='p'
          preview << '<br/><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
        elsif e['typ']=='q'
          preview << '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
        elsif e['typ']=='c'
          preview << '<br/><br/>'
        end
        #preview << "[#{e['rsub']}.#{e['sen']}.#{e['typ']}] #{e['content']} " #to troubleshoot
        ##preview << eval("link_to(#{e['rsen']}, [@translation, @sentence])")
        ##preview << eval("<%= link_to(#{e['rsen']}, [@translation, @sentence]) %> ")
        preview << "#{e['rsen']}: #{e['content']} "
        #preview << "#{e['content']} " #maybe a config can add/remove rsen values?
      end
      return preview
    end
  
    def prev
      if !current_user.cur_assign
        #flash[:danger] = 'You do not have an assignment currently'
        redirect_to root_path and return
      end
  
      @translation = Translation.find(params[:translation_id])
      @sentence = Sentence.find(params[:id])
  
      # update vote time
      #vote_contrib = vote_contribution(@sentence)
      #vote_contrib.update(effort_in_seconds: vote_contrib.effort_in_seconds + stop_vote_timer) if vote_contrib
  
      #update rsen
      prev_rsen = @sentence.rsen - 1
      if prev_rsen < 1
        prev_rsen = 1
        flash[:danger] = 'This is the first sentence.'
      end
      current_user.cur_assign.update(place: prev_rsen)
  
      #update @pred_sentences
      #@pred_sentences= @translation.sentences.where(rsen: prev_rsen-5..prev_rsen-1)
  
      #update @sentence 
      @sentence = @translation.sentences.where(rsen: prev_rsen).first
  
      #update @succ_sentences
      #@succ_sentences= @translation.sentences.where(rsen: prev_rsen+1..prev_rsen+5)
  
      redirect_to translation_sentence_path(@translation, @sentence)
    end
  
    def next
      #require_cur_assign
      if !current_user.cur_assign
        #flash[:danger] = 'You do not have an assignment currently'
        redirect_to root_path and return
      end
  
      @translation = Translation.find(params[:translation_id])
      @sentence = Sentence.find(params[:id])
  
      # update vote time
      #vote_contrib = vote_contribution(@sentence)
      #vote_contrib.update(effort_in_seconds: vote_contrib.effort_in_seconds + stop_vote_timer) if vote_contrib
  
      #update rsen
      next_rsen = @sentence.rsen + 1
      if next_rsen > @translation.senc
        next_rsen = @translation.senc 
        flash[:danger] = 'This is the last sentence.'
      end
      current_user.cur_assign.update(place: next_rsen)
  
      #update @pred_sentences
      #@pred_sentences= @translation.sentences.where(rsen: next_rsen-5..next_rsen-1)
  
      #update @sentence 
      @sentence = @translation.sentences.where(rsen: next_rsen).first
      #puts "next sentence ***************** id=#{@sentence.id}"
      #render template: '/sentences/show', locals: {translation_id: @translation.id}
      #render action: 'show', params: {translation_id: @translation.id}
      #WORKS: redirect_to action: 'show', translation_id: @translation.id, id: @sentence.id
   
      #update @succ_sentences
      #@succ_sentences= @translation.sentences.where(rsen: next_rsen+1..next_rsen+5)
  
      redirect_to translation_sentence_path(@translation, @sentence) and return
    end
  
    def decrease_context
      if !current_user.cur_assign
        #flash[:danger] = 'You do not have an assignment currently'
        redirect_to root_path and return
      end
  
      @translation = Translation.find(params[:translation_id])
      @sentence = Sentence.find(params[:id])
  
      # update vote time
      #vote_contrib = vote_contribution(@sentence)
      #vote_contrib.update(effort_in_seconds: vote_contrib.effort_in_seconds + stop_vote_timer) if vote_contrib
  
      #@@context -= 1
      session[:context] -= 1
      #if @@context < 0
      if session[:context] < 0
        #@@context = 0
        session[:context] = 0
        flash[:danger] = 'This is the minimum context.'
      end
  
      redirect_to translation_sentence_path(@translation, @sentence)
    end
  
    def increase_context
      if !current_user.cur_assign
        #flash[:danger] = 'You do not have an assignment currently'
        redirect_to root_path and return
      end
  
      @translation = Translation.find(params[:translation_id])
      @sentence = Sentence.find(params[:id])
  
      # update vote time
      #vote_contrib = vote_contribution(@sentence)
      #vote_contrib.update(effort_in_seconds: vote_contrib.effort_in_seconds + stop_vote_timer) if vote_contrib
  
      #@@context += 1
      session[:context] += 1
      #if @@context > 10
      if session[:context] > 10
        #@@context = 10
        session[:context] = 10
        flash[:danger] = 'This is the maximum context.'
      end
  
      redirect_to translation_sentence_path(@translation, @sentence)
    end
  
    def sentence_vote_time(sentence)
      svc = sentence_vote_contribution(sentence)
      if svc
        svc.effort_in_seconds
      else
        0
      end
    end
  
    #def vote_timer_status
    #  session[:vote_timer_status]
    #end
  
    def sentence_vote_contribution(sentence)
      sentence_vote_contribs = Contribution.joins(edit: :sentence).joins(:assignment).where(sentences: {id: sentence.id}, contributions: {kind: 'V', assignment_id: current_user.cur_assign.id})
      if sentence_vote_contribs.length > 0
        sentence_vote_contrib = sentence_vote_contribs.first
      else
        sentence_vote_contrib = nil
      end
      sentence_vote_contrib
    end
  
    def sentence_create_time(sentence)
      sccs = sentence_create_contributions(sentence)
      sccs.sum("effort_in_seconds")
    end
  
    #def create_timer_status
    #  session[:create_timer_status]
    #end
  
    def sentence_create_contributions(sentence)
      sentence_create_contribs = Contribution.joins(edit: :sentence).joins(:assignment).where(sentences: {id: sentence.id}, contributions: {kind: 'C', assignment_id: current_user.cur_assign.id})
    end
  
    def timeout
      stop_vote_timer
      stop_create_timer
      redirect_to timeout_path
    end
  
    # GET /sentences/1
    # GET /sentences/1.json
    def show
      require_cur_assign
  
      start_vote_timer
      start_create_timer
      
      #update @pred_sentences
      #@pred_sentences= @translation.sentences.where(rsen: @sentence.rsen-5..@sentence.rsen-1)
        
      #update @succ_sentences
      #@succ_sentences= @translation.sentences.where(rsen: @sentence.rsen+1..@sentence.rsen+5)
  
      # get the English contribution
  =begin
      @sentence.edits.each do |edit|
        edit.contributions.each do |cont|
          @E_contribution = cont if cont.kind == 'E'
        end
      end
  =end
  
      #ensure session has a context value - gone if cur_assign has been set to nil for de-activation
      if not session[:context]
        session[:context] = 0
      end
   
      #update pred_E_edits
      @pred_E_edits = Edit.joins(sentence: :translation).where(translations: {id: @sentence.translation.eng_tran_id}, sentences: {rsen: @sentence.rsen-session[:context]..@sentence.rsen-1})
      
      #update E_edit
      @E_edit = Edit.joins(sentence: :translation).where(translations: {id: @sentence.translation.eng_tran_id}, sentences: {rsen: @sentence.rsen}).first
      
      #update succ_E_edits
      @succ_E_edits = Edit.joins(sentence: :translation).where(translations: {id: @sentence.translation.eng_tran_id}, sentences: {rsen: @sentence.rsen+1..@sentence.rsen+session[:context]})
  
      #render :show 
    end
  
    # GET /sentences/new
    def new
      require_admin
      @sentence = Sentence.new
    end
  
    # GET /sentences/1/edit
    def edit
      require_admin
    end
  
    # POST /sentences
    # POST /sentences.json
    def create
      require_admin
      # debugger
      #@sentence = Sentence.new(sentence_params)
      @sentence = @translation.sentences.new(sentence_params)
  
      if @sentence.save
        flash[:success] = 'Sentence was successfully created.'
        redirect_to translation_sentence_path(@translation, @sentence)
      else
        render :new
      end
    end
  
    # PATCH/PUT /sentences/1
    # PATCH/PUT /sentences/1.json
    def update
      require_admin
      if @sentence.update(sentence_params)
        flash[:success] = 'Sentence was successfully updated.'
        redirect_to translation_sentence_path(@translation, @sentence) 
      else
        render :edit
      end
    end
  
    # DELETE /sentences/1
    # DELETE /sentences/1.json
    def destroy
      require_admin
      @sentence.destroy
      flash[:danger] = 'Sentence was successfully destroyed.'
      redirect_to translation_sentences_path(@translation, @sentence)
    end
  
    private
      def get_translation
        @translation = Translation.find(params[:translation_id])
      end
  
      # Use callbacks to share common setup or constraints between actions.
      def set_sentence
        #@sentence = Sentence.find(params[:id])
        @sentence = @translation.sentences.find(params[:id])
      end
  
      # Never trust parameters from the scary internet, only allow the white list through.
      def sentence_params
        params.require(:sentence).permit(:rsen, :blk, :rsub, :sen, :typ, :tie, :translation_id, :place, :search_term, :commit)
      end
  
      def require_admin
        if !user_signed_in? || (user_signed_in? and !current_user.admin?)
          flash[:danger] = 'Only admins can perform that action'
          redirect_to root_path
        end
      end
  
      def require_sign_in
        if !user_signed_in?
          flash[:danger] = 'You must first sign in'
          redirect_to new_user_session_path
        end
      end
  
      def require_cur_assign
        if !current_user.cur_assign
          flash[:danger] = 'You do not have an assignment currently. Please click on the Assignments menu item and select an assignment.'
          redirect_to root_path and return
        end
      end
  end