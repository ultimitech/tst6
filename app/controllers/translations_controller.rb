class TranslationsController < ApplicationController
  before_action :get_message, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  before_action :set_translation, only: [:show, :edit, :update, :destroy]
  before_action :require_admin

  def all_translations
    @all_translations = Translation.all
  end

  # GET /translations
  # GET /translations.json
  def index
    # @translations = Translation.all
    # @translations = Translation.paginate(page: params[:page], per_page: 3)
    @translations = @message.translations
  end

  # GET /translations/1
  # GET /translations/1.json
  def show
  end

  # GET /translations/new
  def new
    #@message_options = Message.all.map { |m| [m.descriptor + " " + m.title, m.id] }
    #@translator_options = User.all.map { |u| [u.username, u.id] }
	  
    @translation = Translation.new
  end

  # GET /translations/1/edit
  def edit
    #@message_options = Message.all.map { |m| [m.descriptor + " " + m.title, m.id] }
  end

  # POST /translations
  # POST /translations.json
  def create
    # determine if message has been imported already
    language = params[:translation][:lan]
    transcription = params[:translation][:xcrip]
    #translator = params[:translation][:file_name]
    #translator = @message.translations.
    #translationsOTH = @message.translations.where(lan: language, xcrip: transcription, )
#Translation.joins(:users).where(assignments: {role: 'TRANSLATOR'}, users: {username: 'steest'}, translations: {message_id: @message.id})
    #populate translators drop-down
    #@translators = User.joins(:roles).where(roles: {name: 'TRANSLATOR'}) 
	  
    
    ###@translation = Translation.new(translation_params)
    @translation = @message.translations.new(translation_params)


    if @translation.save
      flash[:success] = "Translation was successfully created"
      redirect_to message_translation_path(@message, @translation)
    else
      render 'new'
    end
  end

  # PATCH/PUT /translations/1
  # PATCH/PUT /translations/1.json
  def update
    if @translation.update(translation_params)
      flash[:success] = "Translation was successfully updated"
      redirect_to message_translation_path(@message, @translation)
    else
      render 'edit'
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.json
  def destroy
    @translation.destroy  
    flash[:danger] = "Translation was successfully deleted"
    redirect_to message_translations_path
  end

  def destroy_sentences
    #get_message
    #set_translation
    @translation = Translation.find(params[:id])
    @translation.sentences.each do |sentence|
      sentence.destroy
    end
    flash[:danger] = 'All sentences for this translation deleted'
    redirect_to message_translation_path(@translation.message, @translation)
  end

  def destroy_lookups
    @translation = Translation.find(params[:id])

    # determine the lookups to be deleted
    lookups = @translation.lookups

    num_of_lookups = lookups.length
    puts "num_of_lookups: #{num_of_lookups}"
    if num_of_lookups > 0
      lookups.each do |lu|
        lu.destroy
      end
    
      #mark as not imported 
      @translation.update(li: false) 

      flash[:danger] = "#{num_of_lookups} lookups for this translation deleted"
    else
      flash[:danger] = 'No lookups for this translation deleted'
    end

    redirect_to message_translation_path(@translation.message, @translation)
  end

  def import_lookup_form
    @translation = Translation.find(params[:id])
  end

  def import_lookup
    @translation = Translation.find(params[:id])

    # upload file
    uploaded_io = params[:translation][:file_name]
    File.open(Rails.root.join('public', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end

    # read uploaded file and populate database
    num_of_lookups = 0 
    File.foreach("#{Rails.root}/public/#{uploaded_io.original_filename}").with_index do |line, line_num|
      #next if line_num == 0

      if !line.strip.empty?
        puts line

	# get line parts
        line_parts = line.split(' ', 3) #split by space into 3 parts

	# get blk
        blk = line_parts[0]

	# get sub
        sub = line_parts[1]

	# get rsub
        rsub = line_parts[2]

        # create lookup
        new_lookup = Lookup.create(blk: blk, sub: sub, rsub: rsub, translation: @translation)
	if new_lookup
          puts "new_lookup: #{new_lookup.blk} #{new_lookup.sub} #{new_lookup.rsub}" 
        else
          flash[:danger] = "ERROR: Could not create lookup #{new_lookup.blk} #{new_lookup.sub} #{new_lookup.rsub}"
          redirect_to message_translation_path(@translation.message, @translation)
        end

        new_lookup = nil
        num_of_lookups += 1
      end #if
    end #File

    #delete uploaded file
    #todo
    
    #mark as imported 
    @translation.update(li: true) 
    
    flash[:success] = "#{num_of_lookups} lookups for this translation imported"
    redirect_to message_translation_path(@translation.message, @translation)
  end

  def randomize_translate_contributions
#number_of_translate_assignments = 2 
    number_of_translate_assignments = params[:number_of_translate_assignments].to_i
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ number_of_translate_assignments = #{number_of_translate_assignments}" 
    @translation = Translation.find(params[:id])
    num_of_randomizations = 0 
    @translation.sentences.each do |sentence|
      edits = sentence.edits.order('created_at')
      if edits.length == number_of_translate_assignments #there are ONLY translate (T) contributions when this is done, i.e. no Vote or Create contributions yet
        times = []
        edits.each { |e| times << e.created_at } #populate times array with the created_at of each edit
        random_times = times.sample(edits.length) #take random sample of the created_at times of all edits because edits are ordered by created_at on proofread page
        edits.each_with_index do |edit, i|
          edit.created_at = random_times[i]
	  edit.save
        end
	puts "++++++++++++++++++++++++++++++++++++++++++++++++ Randomization performed for sentence with rsen=#{sentence.rsen}"
        num_of_randomizations += 1 
      elsif edits.length > number_of_translate_assignments
        puts "------------------------------------------------ Number of edits for sentence with rsen=#{sentence.rsen} is #{edits.length}. That is greater than the number of translate assignments (#{number_of_translate_assignments}). Some Create (C) edits may have already been added, or the number of translate assignments are wrong  - no randomization performed."
      else #edits.length < number_of_translate_assignments
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Number of edits for sentence with rsen=#{sentence.rsen} is #{edits.length}. That is less than the number of translate assignments (#{number_of_translate_assignments}). This is not allowed  - no randomization performed."
      end
    end

    #mark as randomized 
    @translation.update(li: true) 
    
    flash[:success] = "#{num_of_randomizations} out of #{@translation.sentences.length} randomizations have been performed for this translation. For each sentence, the number of edits must equal the number of translate assignments exactly, else a randomization will not be performed for that sentence."
    redirect_to message_translation_path(@translation.message, @translation)
  end

  private
    def get_message
      @message = Message.find(params[:message_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_translation
      # @translation = Translation.find(params[:id])
      @translation = @message.translations.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def translation_params
      params.require(:translation).permit(:lan, :tran_title, :eng_tran_id, :descrip, :blkc, :subc, :senc, :xcrip, :message_id, :file_name, :li, :number_of_translate_assignments, :pubdate, :version)
    end

    def require_admin
      if !user_signed_in? || (user_signed_in? and !current_user.admin?)
        flash[:danger] = 'Only admins can perform that action'
        redirect_to root_path
      end
    end
    
end