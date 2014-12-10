module ApplicationHelper

  include DateHelper
  include Revs::Utils
  
  def validation_errors(obj)

    return '' if obj.errors.empty?

    messages = obj.errors.full_messages.map { |msg| content_tag(:li, msg) }.join

    html = <<-HTML
    <div class="alert alert-error alert-block"> <a class="close" href="#" data-dismiss="alert">x</a>
     #{messages}
    </div>
    HTML

    html.html_safe
    
  end
  
  def google_analytics 
    <<-HTML
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', '#{GOOGLE_ANALYTICS_CODE}', 'stanford.edu');
        ga('send', 'pageview');

      </script>
    HTML
  end
    
  # pass in a user, if it's the currently logged in user, you will get the full name; otherwise you will get the appropriate name for public display; if you pass in a url as a second parameter, you will get a link back to that url
  def display_user_name(user,link=nil)
     display = is_logged_in_user?(user) ? user.full_name : user.to_s
     link ? link_to(display,link) : display
  end
 
   # pass in a user, if it's the currently logged in user, you will get the full name; otherwise you will get the appropriate name for public display; it will also created a link if the profile is public, if its you or if you are able to read any profile (e.g. admin)
  def link_user_name(user)
     display_user_name(user,user.public || user == current_user || can?(:read,User) ? user_path(user.username) : nil)
  end

  def display_gallery_visibility(gallery)
    case gallery.visibility.to_sym 
      when :public 
        t('revs.user.public').downcase
       when :private 
        t('revs.user.private').downcase 
       when :curator 
        t('revs.search.gallery_toggle.curator').downcase
    end 
  end

  def available_sizes
   sizes=["'thumb'","'zoom'"]
   sizes+=["'small'","'medium'","'large'","'xlarge'","'full'"] if sunet_user_signed_in?
   return sizes.join(',')    
  end
  
  def home_or_back
    url = request.referrer || root_path
    link_to t('revs.nav.go_back'),url
  end
  
  # take in a hash of options for the contact us form, and then pass the values of the hash through the translation engine
  def translate_options(options)
    result={}
    options.each {|k,v| result.merge!({k=>I18n.t(v)})}
    return result
  end

  def fix_revs_institute_name(title)
    title.gsub('of the Revs Institute','of The Revs Institute')
  end
  
  def show_linked_value(val,opts={})
    value = (opts[:simple_format].blank? ? val : simple_format(val))
    if opts[:facet].blank?
      value
    else
      if SolrDocument.field_mappings[opts[:facet].to_sym][:field] == 'pub_year_isim' # if its the year, formulate the correct date range query
        link = catalog_index_path(:"range[pub_year_isim][begin]" => "#{val}", :"range[pub_year_isim][end]" => "#{val}")      
      else
        link = catalog_index_path(:"f[#{SolrDocument.field_mappings[opts[:facet].to_sym][:field]}][]"=>"#{val}")
      end
      link_to(value,link)
    end
  end
  
  def show_formatted_list(mvf,opts={})
    return "" if mvf.blank?
    return show_linked_value(mvf,opts) if mvf.class != Array
    separator=opts[:separator] || ', '
    return mvf.collect {|val|show_linked_value(val,opts)}.join(separator).html_safe
  end
  
  def render_locale_class
    "lang-#{I18n.locale}"
  end

  def put_cursor_in_searchbox?
    params[:q].to_s.empty? and params[:f].to_s.empty? and params[:id].nil? and controller_name != 'sessions' and controller_name != 'registrations'
  end

  # crete a link to an item
  # opts[:length] can be set to the length to truncate the text title (defaults to 100)
  # opts[:truncate] can be set to true or false to indicate if long titles should be truncated (defaults to false)
  # opts[:target] can be set to "_blank" or another value to target the link
  def item_link(item,opts={})
    if item.nil?  
      return t('revs.curator.not_found')
    else
      length = (opts[:length].to_i == 0 ? 100 : opts[:length].to_i)
      name=opts[:truncate] ? truncate(item.title,:length=>length) : item.title
      return link_to name,item_path(item.id,opts[:params]),target: opts[:target]
    end
  end
  
  def has_activity?(user)
    favorites_count(user) > 0 || annotations_count(user) > 0 || flags_count(user) > 0 || edits_count(user) > 0 || galleries_count(user) > 0
  end
  
  def favorites_count(user)
    user.favorites(current_user).count
  end
  
  def galleries_count(user)
    user.galleries(current_user).count
  end
  
  def annotations_count(user)
    user.annotations(current_user).count
  end

  def flags_count(user)
    user.flags(current_user).count
  end
  
  def edits_count(user)
    user.metadata_updates.count.keys.count
  end
  
  def flags_unresolved_count(user)
    return user.flags(current_user).where(:state=>Flag.open).count
  end
  
  def flags_resolved_count(user)
    return flags_count(user) - flags_unresolved_count(user)
  end

  def display_sidebar_searchbox
    action_name == 'index' && controller_name == 'catalog'
  end

  def on_edit_page
    ["edit","edit_account","update"].include? action_name
  end
  
  def on_user_profile_page
    ['show'].include?(action_name) && controller_name == 'user'
  end
  
  def in_curator_edit_mode
    (session[:curator_edit_mode].blank? || session[:curator_edit_mode] == 'false') ? false : can?(:curate,:all)
  end
  
  def display_class(item_count)
    item_count == 0 ? "hidden" : ""
  end
  
  # used to build the drop down menu of available fields for bulk updating -- add the text to be shown to user and the field in solr doc and Editstore fields table
  def bulk_update_fields
    [
      ['Title','title'],
      ['Formats','formats',{'data-autocomplete-field'=>'format'}],
      ['Years','years_mvf'],
      ['Date','full_date'],
      ['Description','description'],
      ['Marque','marque_mvf',{'data-autocomplete-field'=>'marque'}],
      ['Models','vehicle_model_mvf',{'data-autocomplete-field'=>'vehicle_model'}],
      ['Model Years','model_year_mvf'],
      ['People','people_mvf',{'data-autocomplete-field'=>'people'}],
      ['Entrant','entrant_mvf',{'data-autocomplete-field'=>'entrant'}],
      ['Current Owner','current_owner'],
      ['Venue','venue',{'data-autocomplete-field'=>'venue'}],
      ['Track','track'],
      ['Event','event',{'data-autocomplete-field'=>'event'}],
      ['Street','city_section'],
      ['City','city',{'data-autocomplete-field'=>'city'}],
      ['State','state',{'data-autocomplete-field'=>'state'}],
      ['Country','country',{'data-autocomplete-field'=>'country'}],
      ['Group/Class','group_class'],
      ['Race Data','race_data'],
      ['Photographer','photographer'],
      ['Institutional Notes','institutional_notes']
    ]
  end

  def print_page_link
    html = <<-HTML
    <a href="#" onClick="javascript:window.print(); return false;">
      <button id="print-page" class="btn btn-mini hidden showOnLoad" type="button">Print this page</button>
    </a>
    HTML

    html.html_safe
  end
  
end
