class AssignmentsController < ApplicationController
  #before_filter :get_translation, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  #before_filter :get_user, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  before_action :set_assignment, only: [:show, :edit, :update, :destroy]
  #before_action :require_admin
  before_action :require_admin, except: [:report, :team_assignments]
  ##before_action :require_team_report_authorization, only: [:team_assignments]
  #before_action :require_authorization

  helper_method :assignment_vote_time
  helper_method :assignment_create_time

  def index
    require_admin
    @assignments = Assignment.all
    #@assignments = @translation.assignments
  end

  def status_assignments
    require_admin
    @time_now = Time.now
    #@time_now = Time.new(2017, 8, 31, 0, 0, 0)
    @time_lastweek = @time_now - 7.days

    # 7-day report (uses method4, others have been deleted)
    Assignment.cleanup_report_data #needed, else complains about table existing already
    Assignment.prepare_report_data(@time_lastweek, @time_now, "('TE', 'QE', 'CE')").to_a
    @status_report = Assignment.status_report.to_a
    @status_summary = Assignment.status_summary.to_a.first
    Assignment.cleanup_report_data

    # All-Time Work report
    # TODO: move more logic out of view
    @all_users = User.all.order('username')
    
    # All-Time Translations report
    # TODO: move more logic out of view
    @TE_completed_LA_assignments = Assignment.te_completed_la_assignments()
  end

  def status_assignments_seven_day
    require_admin
    @time_now = Time.now
    #@time_now = Time.new(2017, 8, 31, 0, 0, 0)
    @time_lastweek = @time_now - 7.days

    # 7-day report (uses method4, others have been deleted)
    Assignment.cleanup_report_data #needed, else complains about table existing already
    Assignment.prepare_report_data(@time_lastweek, @time_now, "('TE', 'QE', 'CE')").to_a
    @status_report = Assignment.status_report.to_a
    @status_summary = Assignment.status_summary.to_a.first
    Assignment.cleanup_report_data
  end

  def status_assignments_all_time_work
    require_admin

    # All-Time Work report
    # TODO: move more logic out of view
    @all_users = User.all.order('username')
  end

  def status_assignments_all_time_translations
    require_admin

    # All-Time Translations report
    # TODO: move more logic out of view
    @TE_completed_LA_assignments = Assignment.te_completed_la_assignments()
  end

  def team_assignments
    require_team_report_authorization

    @time_now = Time.now
    #@time_now = Time.new(2017, 8, 31, 0, 0, 0)
    @time_lastweek = @time_now - 7.days

    Assignment.cleanup_report_data #needed, else complains about table existing already
    Assignment.prepare_report_data(@time_lastweek, @time_now, "('TE', 'QE', 'CE')").to_a
    @team_report = Assignment.team_report(current_user.cur_assign.translation.lan).to_a
    @team_summary = Assignment.team_summary(current_user.cur_assign.translation.lan).to_a.first
    Assignment.cleanup_report_data
  end

  def show
    #require_authorization
  end

  def new
    @assignment = Assignment.new(place: 1)
  end

  def edit
  end

  def create
    #get_translation #won't work here
    @assignment = Assignment.new(assignment_params)
    #@translation.assignments << @assignment
    #@user.assignments << @assignment

    if @assignment.save
      flash[:success] = 'Assignment was successfully created.'

      #set user's cur_assign to this newly-created assignment so that a user always have a cur_assign
      #NO: else cur_assign will become nil for each new asn created!
      #@user = User.find(assignment_params[:user_id])
      #@user.cur_assign = @assignment
      #@user.save

      #get_translation #won't work here
      redirect_to assignment_path(@assignment)
      #redirect_to message_translation_path(@translation.message, @translation) 
    else
      render :new
    end
  end

  def editor_complete?(role, from_status, to_status)
    (['TE','CE','QE'].include? role) && (from_status=="ip") && (to_status=="cd") #ip to cd
  end
  def pretranslator_complete?(role, from_status, to_status)
    (['MT','HT','NT'].include? role) && (from_status=="ip") && (to_status=="cd") #ip to cd
  end
  def la_complete?(role, from_status, to_status)
    (['LA'].include? role) && (from_status=="pg") && (to_status=="pd") #pg to pd
  end
  def update
    get_translation
    closeout_editor = editor_complete?(@assignment.role, @assignment.status, assignment_params[:status])
    closeout_pretranslator = pretranslator_complete?(@assignment.role, @assignment.status, assignment_params[:status])
    closeout_la = la_complete?(@assignment.role, @assignment.status, assignment_params[:status])
    closeout = closeout_editor || closeout_pretranslator || closeout_la
    if @assignment.update(assignment_params)
      if closeout
        if closeout_pretranslator
          @assignment.update(ccs: @assignment.contribution_count('T'))
	else
	  @assignment.update(ccs: @assignment.contribution_count('C'))
        end
	@assignment.update(ccs_k: @assignment.contribution_count_with_base('C', 'k'))
	@assignment.update(ccs_m: @assignment.contribution_count_with_base('C', 'm'))

	@assignment.update(vcs: @assignment.contribution_count('V'))
	@assignment.update(vcs_a: @assignment.contribution_count_with_base('V', 'a'))
	@assignment.update(vcs_c: @assignment.contribution_count_with_base('V', 'c'))
	@assignment.update(vcs_t: @assignment.contribution_count_with_base('V', 't'))
	@assignment.update(vcs_p: @assignment.contribution_count_with_base('V', 'p'))
	
	@assignment.update(ct: @assignment.create_time)
	@assignment.update(vt: @assignment.vote_time)
	
	@assignment.update(majtes: @assignment.top_edit_count('M'))
	@assignment.update(tietes: @assignment.top_edit_count('T'))
      end

      #deactivate a user's current assignment
      if @assignment.user.cur_assign    
        #this assignment is the user's cur_assign             && assignment was deactivated
        if (@assignment.id == @assignment.user.cur_assign.id) && assignment_params[:active] == "0"
          @assignment.user.update(cur_assign_id: nil) #don't want user to access a deactivated asn
        end
      end

      if closeout
        flash[:success] = 'Assignment was successfully closed out.'
      else
        flash[:success] = 'Assignment was successfully updated.'
      end
      #redirect_to message_translation_path(@translation.message, @translation) if @translation and return
      redirect_to @assignment
    else
      render :edit and return
    end
  end

  def destroy
    @translation = Translation.find(@assignment.translation.id)
    @assignment.destroy
    flash[:danger] = 'Assignment was successfully destroyed.'
    redirect_to message_translation_path(@translation.message, @translation)
  end

  def destroy_contributions
    @assignment = Assignment.find(params[:id])

    # determine the contributions to be deleted and their kind
    role = @assignment.role
    if ['MT', 'HT'].include? role
      contributions = @assignment.contributions.where("kind = 'T'")
      kind = 'T'
    elsif ['TE', 'CE', 'LA'].include? role
      #contributions = @assignment.contributions.where("kind = 'C' OR kind = 'V'")
      #kind = ['C', 'V']
      flash[:danger] = "ERROR: Deletion of contributions by the roles of TE/CE/LA is not supported"
      redirect_to assignment_path(@assignment) and return
    elsif ['EE', 'SE', 'PE'].include? role
      #contributions = @assignment.contributions.where("kind = 'C'")
      #kind = 'C'
      flash[:danger] = "ERROR: Deletion of contributions by the roles of EE/SE/PE is not supported"
      redirect_to assignment_path(@assignment) and return
    elsif ['EP'].include? role
      contributions = @assignment.contributions.where("kind = 'E'")
      kind = 'E'
    else
      flash[:danger] = "ERROR: Invalid role: #{role}"
      redirect_to assignment_path(@assignment) and return
    end

    # test if safe to delete
    num_of_contributions = contributions.length
    puts "num_of_contributions: #{num_of_contributions}"
    if num_of_contributions > 0
      contributions.each do |cont|
        cont_edit = cont.edit
	cont_edit_sentence = cont.edit.sentence

        if cont_edit.contributions.count > 1
          flash[:danger] = "ERROR: Cannot destroy edit: #{cont_edit.id}. It has other contributions pointing to it!"
          redirect_to assignment_path(@assignment) and return
        end

	if (cont_edit_sentence && cont_edit_sentence.edits.count > 1)
          flash[:danger] = "ERROR: Cannot destroy sentence: #{cont_edit_sentence.id}. It has other edits pointing to it!"
          redirect_to assignment_path(@assignment) and return
        end
      end
    end 

    # destroy
    num_of_contributions = contributions.length
    puts "num_of_contributions: #{num_of_contributions}"
    if num_of_contributions > 0
      contributions.each do |cont|
        cont_edit = cont.edit
	cont_edit_sentence = cont.edit.sentence

        cont.destroy
        cont_edit.destroy
        cont_edit_sentence.destroy if cont_edit_sentence
      end
    
      #mark as not imported 
      @assignment.update(ci: false) 

      flash[:danger] = "#{num_of_contributions} '#{kind}' contributions for this assignment deleted"
    else
      flash[:danger] = 'No contributions for this assignment deleted'
    end

    redirect_to assignment_path(@assignment)
  end

  def import_content_form
    set_assignment
    if @assignment.translation.eng_tran #import MT/HT translate content
      if @assignment.translation.eng_tran.li == false
        flash[:danger] = "ERROR: First import the ENG translation's lookup"
        redirect_to assignment_path(@assignment) and return
      end
    else #import EP English content
      if @assignment.translation.li == false
        flash[:danger] = "ERROR: First import the ENG translation's lookup"
        redirect_to assignment_path(@assignment) and return
      end
    end
  end

  def validate_content
    set_assignment

    # upload file
    uploaded_io = params[:assignment][:file_name]
    File.open(Rails.root.join('public', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end

    # validate the uploaded file
    rsub_sen_ary = []
    File.foreach("#{Rails.root}/public/#{uploaded_io.original_filename}").with_index do |line, line_num|
      next if line_num == 0

      if !line.strip.empty?
        puts line

        # test line for valid descriptor
        unless( line =~ /^[0-9]+\.[0-9]+\.[ncspqkhijv]\s/ ) 
          puts "ERROR: #{line}"
          flash[:danger] = "ERROR: Invalid descriptor in line: #{line}  (Validation failed. Import aborted.)"
          File.delete("#{Rails.root}/public/#{uploaded_io.original_filename}")
          redirect_to assignment_path(@assignment) and return
        end
        
	# test for unique rsub.sen combinations
	# get line parts
        line_parts = line.split(' ', 2) #split by space into 2 parts

	# get descriptor
        descriptor = line_parts[0]

	# get descriptor parts
        descriptor_parts = descriptor.split('.') 
        rsub = descriptor_parts[0]
	sen = descriptor_parts[1]
	rsub_sen = rsub + '.' + sen
        if rsub_sen_ary.include? rsub_sen 
          puts "ERROR: Duplicate rsub.sen combination found in line: #{line}  (Validation failed. Import aborted.)"
          flash[:danger] = "ERROR: Duplicate rsub.sen combination found in line: #{line}  (Validation failed. Import aborted.)"
          File.delete("#{Rails.root}/public/#{uploaded_io.original_filename}")
          redirect_to assignment_path(@assignment) and return
        else
	  rsub_sen_ary << rsub_sen
        end
      end #if non-empty line
    end #File

    #delete uploaded file
    File.delete("#{Rails.root}/public/#{uploaded_io.original_filename}")
    
    required_unique_combinations = @assignment.translation.senc
    found_unique_combinations = rsub_sen_ary.uniq.length
    puts "Unique rsub.sen combinations required: #{required_unique_combinations}"
    puts "Unique rsub.sen combinations found: #{found_unique_combinations}"
    #if(found_unique_combinations != required_unique_combinations)

    flash[:success] = "Unique rsub.sen combinations found: #{found_unique_combinations}, Required:  #{required_unique_combinations}."
    redirect_to assignment_path(@assignment)
  end

  def import_content
    set_assignment
   
    # determine the kind of contributions to be created
    role = @assignment.role
    if ['MT', 'HT', 'NT'].include? role
      kind = 'T'
    elsif ['TE', 'CE', 'LA'].include? role #both 'C' and 'V' kinds
      flash[:danger] = "Content import for role #{role} is not currently supported"
      redirect_to assignment_path(@assignment) and return
    elsif ['EE', 'SE', 'PE'].include? role #'C' kind
      flash[:danger] = "Content import for role #{role} is not currently supported"
      redirect_to assignment_path(@assignment) and return
    elsif ['EP'].include? role
      kind = 'E'
    else
      flash[:danger] = "ERROR: Invalid role: #{role}"
      redirect_to assignment_path(@assignment) and return
    end

    # upload file
    uploaded_io = params[:assignment][:file_name]
    File.open(Rails.root.join('public', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    
    # read uploaded file and populate database
    num_of_contributions = 0 
    File.foreach("#{Rails.root}/public/#{uploaded_io.original_filename}").with_index do |line, line_num|
      next if line_num == 0

      if !line.strip.empty?
        puts line

	# get line parts
        line_parts = line.split(' ', 2) #split by space into 2 parts

	# get descriptor
        descriptor = line_parts[0]

	# get content
        ##content = line_parts[1]
	content = line_parts[1].chomp #remove NL at end

	# get descriptor parts
        descriptor_parts = descriptor.split('.') 
        rsub_num = descriptor_parts[0].to_i
	sen_num = descriptor_parts[1].to_i
	typ_char = descriptor_parts[2]

	#check if sentence already exists, if not, create
	existing_sen = Sentence.joins(:translation).where(translations: {id: @assignment.translation_id}, sentences: {rsub: rsub_num, sen: sen_num})
	#existing_sen = Sentence.joins(:translation).where(translations: {lan: 'ENG'}, sentences: {rsub: rsub_num, sen: sen_num})
	#existing_sen = Sentence.joins(translation: :message).where(translations: {lan: 'ENG', message_id: @assignment.translation.message_id}, sentences: {rsub: rsub_num, sen: sen_num})
	if existing_sen.length == 0
          if @assignment.translation.eng_tran #OTH
            lookup = @assignment.translation.eng_tran.lookups.where(rsub: rsub_num).first
          else #ENG
            lookup = @assignment.translation.lookups.where(rsub: rsub_num).first
          end
		  
          blk_num = lookup.blk
          sub_num = lookup.sub 
          existing_sen = Sentence.create(rsen: num_of_contributions+1, blk: blk_num, sub: sub_num, rsub: rsub_num, sen: sen_num, typ: typ_char, tie: false, translation: @assignment.translation)
	elsif existing_sen.length == 1 
          existing_sen = existing_sen.first
        else
          flash[:danger] = "There is more than one sentence with rsub: #{rsub_num} and sen: #{sen_num}. This is an error!"
          redirect_to assignment_path(@assignment) and return
        end

	#create new edit
        new_edit = Edit.create(content: content, hid: false, top: 'Z', sentence: existing_sen)
	#puts "--- #{new_edit.edit_text}"
	if new_edit
          puts "new_edit: #{new_edit.content}" 
        else
          flash[:danger] = "ERROR: Could not create edit with content: #{content}, sentence: #{existing_sen.id}."
          #redirect_to assignment_path(@assignment) and return
          redirect_to user_path(@assignment.user) and return
        end

	#create contribution
        new_contribution = Contribution.create(kind: kind, effort_in_seconds: 0, edit: new_edit, assignment: @assignment)
	#puts "--- #{new_contribution.contribution_text}"
	if new_contribution
          puts "new_contribution: #{new_contribution.edit.content}" 
        else
          flash[:danger] = "ERROR: Could not create contribution with kind: #{kind}, edit: #{new_edit.id}."
          #redirect_to assignment_path(@assignment) and return
          redirect_to user_path(@assignment.user) and return
        end

        new_edit = nil
        new_contribution = nil
        num_of_contributions += 1
      end #if non-empty line
    end #File

    #delete uploaded file
    File.delete("#{Rails.root}/public/#{uploaded_io.original_filename}")
    
    #mark as imported 
    @assignment.update(ci: true) 
    
    flash[:success] = "#{num_of_contributions} '#{kind}' contributions for this assignment imported"
    redirect_to assignment_path(@assignment)
  end

  #if in future you need to have a specific button for closeout, model after 'Randomize Translate Contributions' on Translation show page
  #def closeout
    #set_assignment
    #@assignment.update(ccs: 777) 
    #flash[:success] = "Assignment with id #{@assignment.id} was closed out."
    #redirect_to assignment_path(@assignment)
  #end

  def report
    set_assignment
  end

  private
    def get_translation
      set_assignment
      #@translation = Translation.find(@assignment.translation) if @assignment.translation
      @translation = Translation.find(@assignment.translation.id) if @assignment.translation
    end

    def get_user
      set_assignment
      @user = User.find(@assignment.user)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_assignment
      @assignment = Assignment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def assignment_params
      #params.require(:assignment).permit(:role, :active, :ci, :place, :translation_id, :user_id)
      params.require(:assignment).permit(:role, :active, :ci, :place, :translation_id, :user_id, :file_name, :status, :ccs, :vcs, :ct, :vt, :majtes, :tietes, :ccs_m, :ccs_k, :vcs_a, :vcs_c, :vcs_t, :vcs_p, :created_at, :notes)
    end

    def require_admin
      if !user_signed_in? || (user_signed_in? and !current_user.admin?)
        flash[:danger] = 'Only admins can perform that action'
        redirect_to root_path
        #redirect_to :back
      end
    end

    def require_authorization
      if !logged_in? || (logged_in? and @assignment.user.id != current_user.id)
        flash[:danger] = 'You do not have authorization to perform this action'
        redirect_to root_path
        #redirect_to :back
      end
    end

    def require_team_report_authorization
      #if !logged_in? || (logged_in? and @assignment.user.id != current_user.id)
      if !user_signed_in? || (user_signed_in? and current_user.cur_assign.role != 'CE')
        flash[:danger] = 'You do not have authorization to perform this action'
        redirect_to root_path
        #redirect_to :back
      end
    end
end