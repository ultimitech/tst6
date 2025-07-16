class DashExportsController < ApplicationController
    def new
      @dash_export = DashExport.new
    end
  
    def create
      @dash_export = DashExport.new(dash_export_params)
      #if @dash_export.save
      if @dash_export.valid?
  
        # set @translation
        @translation = current_user.cur_assign.translation
  
        mode =  params[:dash_export][:export_mode]
        format =  params[:dash_export][:export_format]
  
        # prepare text file
        file_name = "dash_export"
        if format == 'DASH_T'	
          file_ext = "-t.txt"
        else #DASH_B
          file_ext = "-b.txt"
        end
        #full_file_name ="#{Rails.root}/public/#{file_name}#{file_ext}"
        full_file_name ="#{Rails.root}/tmp/#{file_name}#{file_ext}"
        #full_file_name ="#{Rails.root}/log/#{file_name}#{file_ext}"
  
        # NOT NECESSARY - ensure no previous file is present
        #File.delete(full_file_name) if File.exist?(full_file_name)
  
        # NOT NECESSARY - preserve file name 
        #session[:full_file_name] = full_file_name
  
        if mode == 'REMOTE'
          #DashExportsController.delay.prepare_dash_export_file(mode, format, full_file_name, params, @translation)
          #self.delay.prepare_dash_export_file(mode, format, full_file_name, params, @translation)
          DashExportsController.new.delay.prepare_dash_export_file(mode, format, full_file_name, params, @translation)
        else
          prepare_dash_export_file(mode, format, full_file_name, params, @translation)
        end
  
  =begin #cannot have here because the prepared file is not ready yet!
  =end
  
        #format.html { redirect_to(success_path, notice: 'ExportTextConfig was successfully submitted.') and return }
          #redirect_to(success_path) and return
      else
          #format.html { redirect_to new_export_text_config_path, notice: 'ExportTextConfig was not successfull.' and return }
          #format.html { render :new }
      end #if
    end
  
  =begin #does not work
    def download
      name = session[:full_file_name]
      cont = DashExportsController.new
      cont.delay.download_file(cont, name)
    end
  
    #def download
    def download_file(cont, name) 
        #name = session[:full_file_name]
        type = 'text/text; charset=utf-8'
        cont.send_file(name, 
        :type => type, 
            :disposition => 'attachment')
        #File.delete(session[:full_file_name]) #seems like being deleted before fully downloaded
    end
  =end
  
    def success
    end
  
    private
  
    #def self.prepare_dash_export_file(mode, format, full_file_name, pars, translation)
    def prepare_dash_export_file(mode, format, full_file_name, pars, translation)
      #sub_separator = params[:dash_export][:sub_separators]
      sub_separator = pars[:dash_export][:sub_separators]
      if format == 'DASH_T'
        #sub_separator = "<br/>" * sub_separator.to_i
        sub_separator = "\n" * sub_separator.to_i
      else
        sub_separator = "\n" * sub_separator.to_i
      end
      #exclude_scripture_sentences = params[:dash_export][:exclude_scripture_sentences]
      exclude_scripture_sentences = pars[:dash_export][:exclude_scripture_sentences]
      #exclude_poetry_sentences = params[:dash_export][:exclude_scripture_sentences]
      exclude_poetry_sentences = pars[:dash_export][:exclude_scripture_sentences]
  
      cur_rsub = 1
      next_rsub = 1
  
      File.open(full_file_name, 'w') do |f|
        #f << @translation.tran_title
        f << translation.tran_title
        f << sub_separator
  
        #@translation.sentences.order(:rsen).each do |s|
        translation.sentences.order(:rsen).each do |s|
        #TRY: translation.sentences.order(:rsen).joins(:edits).where.not(edits: {top: 'N'})
        #translation.sentences.order(:rsen).joins(:edits).where.not(edits: {top: 'N'}).each do |s|
      next_rsub = s.rsub
  
      if next_rsub > cur_rsub
        f << "#{sub_separator}"
        cur_rsub = next_rsub
          end #if
  
      if (s.typ == 's' && exclude_scripture_sentences == '1') ||
         (s.typ == 'p' && exclude_poetry_sentences == '1') ||
         (s.typ == 'q' && exclude_poetry_sentences == '1')
            content = ""
          else
        ##content = s.edits.where.not(top: 'N').first.content.chomp #TODO: data in db still have \n's
        content = s.edits.where.not(top: 'N').first.content
        #content = s.edits.first.content
      end 
          if format == 'DASH_T'	
            #formatted_content = DashExportsController.dash_t_format(s, content)
            formatted_content = dash_t_format(s, content)
          else #DASH_B
            #formatted_content = DashExportsController.dash_b_format(s, content)
            formatted_content = dash_b_format(s, content)
          end 
      f << "#{cur_rsub}.#{s.sen}.#{s.typ} #{formatted_content}#{sub_separator}"
      
        end #sentences
  
      end #File
  
      if mode == 'REMOTE'
        export_file_remote(full_file_name)
      else
        export_file_local(mode, format, full_file_name)
      end
    end
  
    def export_file_local(mode, format, full_file_name)
        # export file
        if format == 'DASH_T'
          puts "********* export_format: REG"
      ##type = 'text/html; charset=utf-8'
      type = 'text/text; charset=utf-8'
        else #DASH_B
          puts "********* export_format: HUB"
      #type =  'application/octet-stream' #default
      type = 'text/text; charset=utf-8'
        end
        if mode == 'PREVIEW'	
          send_file(full_file_name, 
        :type => type, 
            :disposition => 'inline')
        else #DOWNLOAD
          send_file(full_file_name, 
        :type => type, 
            :disposition => 'attachment')
        end
    end
  
    def export_file_remote(full_file_name)
      # list my AWS buckets
      #s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"]) 
      #s3.buckets.limit(50).each do |b|
      #  puts "#{b.name}"
      #end
  
      # upload to AWS
      s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"]) 
      bucket = ENV["AWS_BUCKET"]
      name = File.basename(full_file_name)
      obj = s3.bucket(bucket).object(name) #create the object to upload
      obj.upload_file(full_file_name) #upload file
      puts "FILE #{name} HAS BEEN UPLOADED TO AWS ..."
  
      # test if dyno finds the prepared file
      #File.foreach(full_file_name).with_index do |line, line_num|
      #  puts "#{line_num}: #{line}"
      #end
    end
  
    def dash_t_format(s, content)
      return if content == ""
      cont = content
  
      # replace all **some words** with some words
      #puts "... replace all **some words** with some words"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*\*([^\*]+)\*\*/, '\1')
      #puts "after: #{cont}"
  
      # replace all *some words* with some words
      #puts "... replace all *some words* with some words"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*([^\*]+)\*/, '\1')
      #puts "after: #{cont}"
      #markdown(reg)
      #reg
      dash_t = cont
    end
  
    def dash_b_format(s, content)
      return if content == ""
      cont = content
  
      #hub = "\n#{sen_num}#{rsen_num}#{cont}" 
      dash_b = cont
    end
  
    def dash_export_params
      params.require(:dash_export).permit(:blk_separators, :sub_separators, :exclude_scripture_sentences, :exclude_poetry_sentences, :show_blk_numbers, :show_sub_numbers, :show_rsub_numbers, :show_sen_numbers, :show_rsen_numbers, :export_mode, :export_format)
    end
  end
  