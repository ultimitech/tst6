class TextExportsController < ApplicationController
    def new
      @text_export = TextExport.new
    end
  
    def create
      @text_export = TextExport.new(text_export_params)
      #if @text_export.save
      if @text_export.valid?
  
        # set @translation
        @translation = current_user.cur_assign.translation
  
        mode =  params[:text_export][:export_mode]
        format =  params[:text_export][:export_format]
  
        # prepare text file
        file_name = "text_export"
        if format == 'REG'
          file_ext = ".html"
        else #HUB
          file_ext = "-mh.txt"
        end
        full_file_name ="#{Rails.root}/tmp/#{file_name}#{file_ext}"
  
        if mode == 'REMOTE'
          #prepare_text_export_file mode, format, full_file_name
          TextExportsController.new.delay.prepare_text_export_file(mode, format, full_file_name, params, @translation)
          #TextExportsController.delay.prepare_text_export_file(format, full_file_name, params, @translation)
        else
          prepare_text_export_file(mode, format, full_file_name, params, @translation)
        end
  
  =begin
  =end
  
        #format.html { redirect_to(success_path, notice: 'ExportTextConfig was successfully submitted.') and return }
          #redirect_to(success_path) and return
      else
          #format.html { redirect_to new_export_text_config_path, notice: 'ExportTextConfig was not successfull.' and return }
          #format.html { render :new }
      end #if
    end
  
  
    def success
    end
  
    private
  
    #def prepare_text_export_file(mode, format, full_file_name)
    def prepare_text_export_file(mode, format, full_file_name, pars, translation)
    #def self.prepare_text_export_file(format, full_file_name, pars, translation)
      #blk_separator = params[:text_export][:blk_separators]
      blk_separator = pars[:text_export][:blk_separators]
      if format == 'REG'
        blk_separator = "<br/>" * blk_separator.to_i
      else
        blk_separator = "\n" * blk_separator.to_i
      end
  
      #sub_separator = params[:text_export][:sub_separators]
      sub_separator = pars[:text_export][:sub_separators]
      if format == 'REG'
        sub_separator = "<br/>" * sub_separator.to_i
      else
        sub_separator = "\n" * sub_separator.to_i
      end
  
      #sen_separator = params[:text_export][:sen_separators]
      sen_separator = pars[:text_export][:sen_separators]
      if format == 'REG'
        sen_separator = "&nbsp;" * sen_separator.to_i
      else
        sen_separator = " " * sen_separator.to_i
      end
  
      show_blk_numbers = pars[:text_export][:show_blk_numbers]
      show_sub_numbers = pars[:text_export][:show_sub_numbers]
      show_rsub_numbers = pars[:text_export][:show_rsub_numbers]
      show_sen_numbers = pars[:text_export][:show_sen_numbers]
      show_rsen_numbers = pars[:text_export][:show_rsen_numbers]
      cur_blk = 1
      next_blk = 1
      cur_sub = 1
      next_sub = 1
      cur_rsub = 1
      next_rsub = 1
  
      File.open(full_file_name, 'w') do |f|
        f << "<div>" if format == 'REG' #for blk
        f << "<div>" if format == 'REG' #for sub
        f << "[#{next_blk}]" if show_blk_numbers == '1'
        f << "\{#{next_sub}\}" if show_sub_numbers == '1'
        f << "<#{next_rsub}>" if show_rsub_numbers == '1'
  
        #@translation.sentences.order(:rsen).each do |s|
        translation.sentences.order(:rsen).each do |s|
          next_blk = s.blk
      next_sub = s.sub
      next_rsub = s.rsub
  
      if (next_blk > cur_blk) && (next_rsub > cur_rsub)
            f << "</div>" if format == 'REG' #for sub
            f << "</div>" if format == 'REG' #for blk
        f << "#{blk_separator}"
            f << "<div>" if format == 'REG' #for blk
            f << "<div>" if format == 'REG' #for sub
            f << "[#{next_blk}]" if show_blk_numbers == '1'
            f << "\{#{next_sub}\}" if show_sub_numbers == '1'
            f << "<#{next_rsub}>" if show_rsub_numbers == '1'
        cur_blk = next_blk
        cur_sub = next_sub
        cur_rsub = next_rsub
          elsif next_rsub > cur_rsub
            f << "</div>" if format == 'REG' #for sub
        f << "#{sub_separator}"
            f << "<div>" if format == 'REG' #for sub
            f << "\{#{next_sub}\}" if show_sub_numbers == '1'
            f << "<#{next_rsub}>" if show_rsub_numbers == '1'
        cur_sub = next_sub
        cur_rsub = next_rsub
          else
          end #if
       
      # place sentence according to type n,s,p,q,c; should be only ONE edit where top is not 'N'
      ##content = s.edits.where.not(top: 'N').first.content.chomp #TODO: data in db still have \n's
      content = s.edits.where.not(top: 'N').first.content
       
          if format == 'REG'	
            #formatted_content = reg_format(s, content, sen_separator)
            #formatted_content = TextExportsController.reg_format(s, content, sen_separator, pars)
            formatted_content = reg_format(s, content, sen_separator, pars)
          else #HUB
            #formatted_content = hub_format(s, content, sen_separator)
            #formatted_content = TextExportsController.hub_format(s, content, sen_separator, pars)
            formatted_content = hub_format(s, content, sen_separator, pars)
          end 
          f << formatted_content
      
        end #sentences
        f << "</div>" if format == 'REG' #for sub
        f << "</div>" if format == 'REG' #for blk
  
      end #File
  
      if mode == 'REMOTE'
        export_file_remote(full_file_name)
      else
        export_file_local(mode, format, full_file_name)
      end
    end
  
    def export_file_local(mode, format, full_file_name)
        # export file
        if format == 'REG'
          puts "********* export_format: REG"
      type = 'text/html; charset=utf-8'
      #type = 'text/text; charset=utf-8'
        else #HUB
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
      # upload to AWS
      s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"]) 
      bucket = ENV["AWS_BUCKET"]
      name = File.basename(full_file_name)
      obj = s3.bucket(bucket).object(name) #create the object to upload
      obj.upload_file(full_file_name) #upload file
      puts "FILE #{name} HAS BEEN UPLOADED TO AWS ..."
    end
  
    #def reg_format(s, content, sen_separator)
    def reg_format(s, content, sen_separator, pars)
    #def self.reg_format(s, content, sen_separator, pars)
      #show_sen_numbers = params[:text_export][:show_sen_numbers]
      show_sen_numbers = pars[:text_export][:show_sen_numbers]
      #show_rsen_numbers = params[:text_export][:show_rsen_numbers]
      show_rsen_numbers = pars[:text_export][:show_rsen_numbers]
      if show_sen_numbers == '1'
        sen_num = "(#{s.sen})"
      else
        sen_num = ""
      end
      if show_rsen_numbers == '1'
        rsen_num = "*#{s.rsen}*"
      else
        rsen_num = ""
      end
  
      cont = content
      # replace all **some words** with <strong>some words</strong>
      #puts "... replace all **some words** with <strong>some words</strong>"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*\*([^\*]+)\*\*/, '<strong>\1</strong>')
      #puts "after: #{cont}"
  
      # replace all *some words* with <em>some words</em>
      #puts "... replace all *some words* with <em>some words</em>"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*([^\*]+)\*/, '<em>\1</em>')
      #puts "after: #{cont}"
  
      if(['h', 'i', 'j'].include? s.typ)
          reg = "#{sen_num}#{rsen_num}#{cont}<br/><br/>"
      elsif (s.typ == 'n')
        if s.sen == 1
          reg = "#{sen_num}#{rsen_num}#{cont}"
        else
          #first 'n' after 'h' will start with sen_separator: remove manually
          reg = "#{sen_separator}#{sen_num}#{rsen_num}#{cont}"
        end
      elsif(['s', 'v'].include? s.typ)
        #reg =  "\n\n   #{sen_num}#{rsen_num}#{cont}" 
        reg =  "<br/><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#{sen_num}#{rsen_num}#{cont}" 
      elsif s.typ == 'p'
        reg = "<br/><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#{sen_num}#{rsen_num}#{cont}"
      elsif s.typ == 'q'
        reg = "<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#{sen_num}#{rsen_num}#{cont}"
      elsif s.typ == 'c'
        reg = "<br/><br/>#{sen_num}#{rsen_num}#{cont}"
      else
        reg = "Unknown sentence type: #{s.typ}"
        reg = "<br/>#{sen_num}#{rsen_num}#{cont}"
      end
  
      #markdown(reg)
      reg
    end
  
    #def hub_format(s, content, sen_separator)
    def hub_format(s, content, sen_separator, pars)
    #def self.hub_format(s, content, sen_separator, pars)
      #show_sen_numbers = params[:text_export][:show_sen_numbers]
      show_sen_numbers = pars[:text_export][:show_sen_numbers]
      #show_rsen_numbers = params[:text_export][:show_rsen_numbers]
      show_rsen_numbers = pars[:text_export][:show_rsen_numbers]
      if show_sen_numbers == '1'
        sen_num = "(#{s.sen})"
      else
        sen_num = ""
      end
      if show_rsen_numbers == '1'
        rsen_num = "*#{s.rsen}*"
      else
        rsen_num = ""
      end
  
      cont = content
      if s.typ == 's'
        # surround with ^^ for border conditions
        #puts "... surround with ^^ for border conditions"
        #puts "before: #{cont}"
        cont = "^^#{cont}^^"
        #puts "after: #{cont}"
  
        # replace all *some words* with ^^some words^^
        #puts "... replace all *some words* with ^^some words^^"
        #puts "before: #{cont}"
        cont = cont.gsub(/\*([^\*]*)\*/, '^^\1^^')
        #puts "after: #{cont}"
  
        # delete all ^^^^ (^^ cancels ^^; may occur at beginning and/or end)
        #puts "... delete all ^^^^ (^^ cancels ^^; may occur at beginning and/or end)"
        #puts "before: #{cont}"
        cont = cont.gsub(/\^{4}/, '')
        #puts "after: #{cont}"
  
        # delete all ^^[punctuation]^^ (^^ cancels ^^; may occur st end)
        # if (closing) * comes AFTER the punctuation, then this is not necessary, 
        # e.g. *some words;*
        # but IS necessary for *some words*;
        #puts "... delete all ^^[punctuation]^^ (^^ cancels ^^; may occur at end)"
        #puts "before: #{cont}"
        cont = cont.gsub(/\^{2}([\,\.\?;!])\^{2}/, '\1')
        #puts "after: #{cont}"
  
        # precede with @@ 
        #puts "... precede with @@"
        #puts "before: #{cont}"
        cont = "@@#{cont}"
        #puts "after: #{cont}"
      end
      if (s.typ == 'p') || (s.typ == 'q')
        # precede with %%
        #puts "... precede with %%"
        #puts "before: #{cont}"
        cont = "%%#{cont}"
        #puts "after: #{cont}"
      end
  
      # preserve all **some words** with ##some words##
      # so that next step can work on *some words* 
      #puts "... preserve"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*\*([^\*]+)\*\*/, '##\1##')
      #puts "after: #{cont}"
  
      # replace all *some words* with ++some words++
      #puts "... replace all *some words* with ++some words++"
      #puts "before: #{cont}"
      cont = cont.gsub(/\*([^\*]+)\*/, '++\1++')
      #puts "after: #{cont}"
  
      # restore all ##some words## back to **some words**
      # not necessary to convert - MHub uses **some words** for bold
      #puts "... restore"
      #puts "before: #{cont}"
      cont = cont.gsub(/##([^#]+)##/, '**\1**')
      #puts "after: #{cont}"
  
      ##hub = "\n#{sen_num}#{rsen_num}#{cont}" 
      if(['h', 'i', 'j'].include? s.typ)
          hub = "\n#{sen_num}#{rsen_num}#{cont}\n" 
      elsif (s.typ == 'n')
        if s.sen == 1
          hub = "\n#{sen_num}#{rsen_num}#{cont}" 
        else
          #first 'n' after 'h' will start with sen_separator: remove manually
          hub = "#{sen_separator}#{sen_num}#{rsen_num}#{cont}" 
        end
      else
          hub = "\n#{sen_num}#{rsen_num}#{cont}" 
      end
    end
  
    def text_export_params
      params.require(:text_export).permit(:blk_separators, :sub_separators, :sen_separators, :format_emphases, :format_scripture_sentences, :format_conversation_sentences, :format_poetry_sentences, :show_blk_numbers, :show_sub_numbers, :show_rsub_numbers, :show_sen_numbers, :show_rsen_numbers, :export_mode, :export_format)
    end
  end
  