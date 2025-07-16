class SessionsController < Devise::SessionsController

  def create
    super do |resource|
      if resource.cur_assign
        session[:context] = 0 #store number of surrounding sentences in the session
	session[:preview] = 20 #preview will show 20 previous sentences
	session[:auto_advance_after_vote] = false
	session[:auto_advance_after_save] = false
        if Assignment.admin_roles.include? resource.cur_assign.role
          redirect_to user_path(resource) and return
        else
          translation = resource.cur_assign.translation
	  if translation
	    sentence = translation.sentences.where(rsen: resource.cur_assign.place).first
	    if sentence
              redirect_to translation_sentence_path(translation, sentence) and return
            end
          end
        end
      else
        flash[:success] = 'You do not have an assignment currently. Please click on the Assignments menu item and select an assignment.'
	redirect_to :controller => 'pages', :action => 'home' and return
      end
    end
  end

end