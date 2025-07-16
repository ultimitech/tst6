module AssignmentsHelper
  def format_time_per_sentence(role, time, sentences)
    if ['TE', 'CE'].include? role
      '%.1f' % (time.to_f/sentences) if sentences > 0
    else
      'N/A'
    end
  end

  def format_percent_complete(role, votes, sentences)
    if ['TE', 'CE'].include? role
      '%.1f' % ((votes/sentences)*100) if sentences > 0
    else
      'N/A'
    end
  end

  def format_votes(votes)
    if !votes || votes=='0'
      ''
    else
      votes 
    end
  end

  def format_minutes(minutes)
    if !minutes || minutes=='0'
      ''
    else
      format_hours_minutes(minutes) 
    end
  end

  def format_completion(completion)
    if !completion
      ''
    elsif completion=='0'
      '0%'
    else
      #completion + '%'
      '%.1f' % completion + '%'
    end
  end

  def format_descriptor(desc)
    if desc[0] =~ /[0-9]/ #first char is a number?
      desc = desc[2..-1] #remove first 2 chars: '19'
      desc.gsub!(/b/, 'B')
      desc.gsub!(/s/, 'S')
      desc.gsub!(/x/, 'M')
      desc.gsub!(/y/, 'A')
      desc.gsub!(/z/, 'E')
    end
    desc
  end
 
  def format_hours_minutes(mins)
    hh, mm = mins.to_i.divmod(60)
    "#{hh} hours, #{mm} minutes"
  end

=begin
  def content_link()
    if @assignment.ci
      link_to 'Delete Content', { controller: 'assignments', action: 'destroy_contributions', params: {id: @assignment.id} }, data: { confirm: 'Are you sure you want to delete all contributions for this assignment?' }, class: 'btn btn-xs btn-danger'
    else
      [link_to 'Validate Content', validate_content_form_assignment_path, class: 'btn btn-xs btn-primary',   
      link_to 'Import Content', import_content_form_assignment_path, class: 'btn btn-xs btn-primary']
    end
  end      
=end

end