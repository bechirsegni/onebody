class Administration::SyncsController < ApplicationController
  before_filter :only_admins
  
  VALID_SORT_COLS = %w(
    sync_items.name
    sync_items.legacy_id
    sync_items.operation
    sync_items.status
  )
  
  def index
    @syncs = Sync.paginate(
      :order  => 'created_at desc',
      :page   => params[:page]
    )
  end
  
  def show
    unless params[:sort] and params[:sort].to_s.split(',').all? { |col| VALID_SORT_COLS.include?(col) }
      params[:sort] = 'sync_items.status,sync_items.name'
    end
    @sync = Sync.find(params[:id])
    @items = @sync.sync_items.paginate(:order => params[:sort], :page => params[:page])
  end
  
  # for api only
  def create
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      @sync = Sync.create!(params[:sync].merge(:person_id => @logged_in.id))
      respond_to do |format|
        format.xml { render :xml => @sync.to_xml }
      end
    else
      render :text => 'You are not authorized to perform this action.', :status => 401
    end
  end
  
  # for api only
  def update
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      @sync = Sync.find(params[:id])
      @sync.update_attributes!(params[:sync].merge(:person_id => @logged_in.id))
      respond_to do |format|
        format.xml { render :xml => @sync.to_xml }
      end
    else
      render :text => 'You are not authorized to perform this action.', :status => 401
    end
  end
  
  # for api only
  def create_items
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      @sync = Sync.find(params[:id])
      Hash.from_xml(request.body.read)['records'].to_a.each do |item|
        @sync.sync_items.create!(item)
      end
      respond_to do |format|
        format.xml { render :xml => @sync.to_xml }
      end
    else
      render :text => 'You are not authorized to perform this action.', :status => 401
    end
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_sync)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
