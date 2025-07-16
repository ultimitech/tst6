module TranslationsHelper
  def lookup_link(message)
    if @translation.li
      link_to 'Delete Lookup', { controller: 'translations', action: 'destroy_lookups', params: {id: @translation.id} }, data: { confirm: 'Are you sure you want to delete all lookups for this translation?' }, class: 'btn btn-xs btn-danger'
    else
      link_to 'Import Lookup', import_lookup_form_translation_path, message_id: message.id, class: 'btn btn-xs btn-primary'
    end 
  end
end
