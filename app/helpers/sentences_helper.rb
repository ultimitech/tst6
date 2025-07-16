module SentencesHelper
  def top_edit_class(top)
    if top == 'M'
      'top-edit-majority'
    elsif top == 'T'
      'top-edit-tie'
    elsif top == 'Z'
      'top-edit-zero-votes'
    else
      ''
    end
  end

  def voted_for(cur_edit)
    cur_edit.contributions.joins(assignment: :user).where(contributions: {kind: 'V'}, users: {username: current_user.username}).length > 0
  end

  def created(cur_edit)
    cur_edit.contributions.joins(assignment: :user).where(contributions: {kind: 'C'}, users: {username: current_user.username}).length > 0
  end

end
