class CollectionController < ApplicationController

  before_filter :authorize
  
  def index
  	get_paging_params
    @per_page = Revs::Application.config.num_default_per_page_collections # override the default for collections
    @view=params[:view] || 'grid'
	  @collections=Kaminari.paginate_array(SolrDocument.all_collections).page(@current_page).per(@per_page)
    @num_to_show_in_filmstrip=100
  end

  protected
  def authorize
    not_authorized unless can? :read,:collections_page
  end
  
end
