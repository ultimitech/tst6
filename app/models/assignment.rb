#class Assignment < ActiveRecord::Base
class Assignment < ApplicationRecord
  has_many :contributions
  has_many :edits, through: :contributions

  belongs_to :translation
  belongs_to :user

  attr_accessor :file_name, :top_edit_count #virtual attributes: not persisted

  def assignment_text
    "#{translation.translation_text} (#{role}) #{user.username} #{place}"
  end
  
  def self.admin_roles
    ['EP', 'MT', 'HT', 'LA']
  end

  #########################################################
  # STATUS REPORT 
  #########################################################
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # 7-day report
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  def self.cleanup_report_data()
    query = "
drop table if exists todvotes;
    "
    ActiveRecord::Base.connection.select_all(query)

    query = "
drop table if exists todcompletions;
    "
    ActiveRecord::Base.connection.select_all(query)

    query = "
drop table if exists todseconds;
    "
    ActiveRecord::Base.connection.select_all(query)
    
    query = "
drop table if exists todreport;
    "
    ActiveRecord::Base.connection.select_all(query)
  end

  # method4 
  def self.prepare_report_data(from, to, for_roles)
    # votes
    query = "
create temp table todvotes as
select t.username, t.role, t.lan, t.descriptor, t.title, sum(t.count) as votes 
from   (
	select u.username, a.role, t.lan, m.descriptor, m.title, count(*)
	from users as u
	join assignments as a on a.user_id=u.id
	join translations as t on a.translation_id=t.id
	join contributions as c on c.assignment_id=a.id
	join messages as m on t.message_id=m.id
	where a.active = TRUE
	--and a.role in ('TE')
	and a.role in #{for_roles}
	and c.kind='V'
	and c.created_at between '#{from}' and '#{to}'
	group by u.username, a.role, t.lan, m.descriptor, m.title
	UNION ALL
	select u.username, a.role, t.lan, m.descriptor, m.title, 0
	from users as u
	join assignments as a on a.user_id=u.id
	join translations as t on a.translation_id=t.id
	join messages as m on t.message_id=m.id
	where a.active = TRUE
	--and a.role in ('TE')
	and a.role in #{for_roles}
       ) as t
group by t.username, t.role, t.lan, t.descriptor, t.title
order by t.username, t.role, t.lan, t.descriptor, t.title;
    "
    ActiveRecord::Base.connection.select_all(query)

    # completions
    query = "
create temp table todcompletions as 
select u.username, a.role, t.lan, m.descriptor, m.title, (count(*)*100/t.senc::float) as completion 
from users as u
join assignments as a on a.user_id=u.id
join translations as t on a.translation_id=t.id
join contributions as c on c.assignment_id=a.id
join messages as m on t.message_id=m.id
where a.active = TRUE
--and a.role in ('TE')
and a.role in #{for_roles} 
and c.kind='V'
group by u.username, a.role, t.lan, m.descriptor, m.title, t.senc
order by u.username, a.role, t.lan, m.descriptor, m.title, t.senc;
    "
    ActiveRecord::Base.connection.select_all(query)

    # seconds
    query = "
create temp table todseconds as 
select u.username, a.role, t.lan, m.descriptor, m.title, sum(effort_in_seconds) as seconds 
from users as u
join assignments as a on a.user_id=u.id
join translations as t on a.translation_id=t.id
join contributions as c on c.assignment_id=a.id
join messages as m on t.message_id=m.id
where a.active = TRUE
--and a.role in ('TE')
and a.role in #{for_roles} 
and c.kind IN ('V', 'C')
and c.created_at between '#{from}' and '#{to}'
and c.effort_in_seconds < #{Contribution.cutoff} --max 60 mins
group by u.username, a.role, t.lan, m.descriptor, m.title
order by u.username, a.role, t.lan, m.descriptor, m.title;
    "
    ActiveRecord::Base.connection.select_all(query)

    # join votes, completions, and seconds
    query = "
create temp table todreport as 
select v.username, v.role, v.lan, v.descriptor, v.title, v.votes, c.completion, round(s.seconds/60::float) as minutes 
from todvotes as v 
left join todcompletions as c
on c.username=v.username
and c.role=v.role
and c.lan=v.lan
and c.descriptor=v.descriptor
left join todseconds as s 
on v.username=s.username
and v.role=s.role
and v.lan=s.lan
and v.descriptor=s.descriptor;
    "
    ActiveRecord::Base.connection.select_all(query)
  end

  def self.status_report
    # report 
    query = "
select * from todreport order by lan, username, descriptor;
    "
    ActiveRecord::Base.connection.select_all(query)
  end

  def self.status_summary
    query = "
select sum(votes) as votes, sum(minutes) as minutes, count(*) as assignments from todreport;
    "
    ActiveRecord::Base.connection.select_all(query)
  end


  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # All-Time Work report
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # All-Time Translations report
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  def self.te_completed_la_assignments
    where(role: 'LA', status: ['ce', 'qe', 'pg', 'pd', 'pr'])
      .sort_by {|x| [x.translation.lan, x.created_at]}.to_a 
  end




  #########################################################
  # TEAM REPORT 
  #########################################################
  def self.team_report(language)
    # report 
    query = "
select * from todreport where lan = '#{language}';
    "
    ActiveRecord::Base.connection.select_all(query)
  end

  def self.team_summary(language)
    query = "
select sum(votes) as votes, sum(minutes) as minutes, count(*) as assignments from todreport where lan = '#{language}';
    "
    ActiveRecord::Base.connection.select_all(query)
  end

  def top_edit_count(type)
    if self.role == 'MT' || self.role == 'HT'
      kind = 'T'
    elsif self.role == 'TE' || self.role == 'CE' || self.role == 'QE' || self.role == 'LA'
      kind = 'C'
    else
      puts "ERROR: The role #{self.role} does not have a top_edit_count!"
    end
    self.contributions.joins(:edit).where(contributions: {kind: kind}, edits: {top: type}).count
  end

  def total_top_edit_count

  end

  def contribution_count(type)
    self.contributions.where(kind: type).count
  end
  
  def contribution_count_with_base(type, base)
    self.contributions.where(kind: type, base: base).count
  end
  
  def contribution_count_between(type, from, to)
    self.contributions.where(kind: type, created_at: from..to).count
  end
  
  def total_contribution_count
    self.contributions.count
  end

  def sentence_count
    self.translation.sentences.count
  end

  def vote_time
    ##avcs = assignment_vote_contributions(assignment)
    avcs = self.contributions.where(kind: 'V')
    avcs.sum("effort_in_seconds")
  end

  def create_time
    ##accs = assignment_create_contributions(assignment)
    accs = self.contributions.where(kind: 'C') 
    accs.sum("effort_in_seconds")
  end

  def mods_count
    if self.role == 'MT' || self.role == 'HT'
      kind = 'T'
    elsif self.role == 'TE' || self.role == 'CE' || self.role == 'LA'
      kind = 'C'
    else
      puts "ERROR: The role #{self.role} does not have a mods_count!"
    end
    entries = Edit.joins(contributions: :assignment).where(contributions: {kind: kind}, assignments: {id: self.id})
    sum = 0
    entries.each { |entry| sum += entry.mods }
    return sum
  end
end