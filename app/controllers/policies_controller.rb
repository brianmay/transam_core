class PoliciesController < OrganizationAwareController
  #before_filter :authorize_admin
  before_filter :check_for_cancel, :only => [:create, :update]
  before_filter :get_policy, :except => [:index, :create, :new]
  
  SESSION_VIEW_TYPE_VAR = 'policies_subnav_view_type'
  
  # always use generic untyped organizations for this controller
  RENDER_TYPED_ORGANIZATIONS = false
  
  def render_typed_organizations
    RENDER_TYPED_ORGANIZATIONS
  end
  
  def index

    @page_title = 'Policies'
   
    # get the policies for this agency 
    @policies = []
    @organization.policies.each do |p|
      @policies << p
    end   
    
    # remember the view type
    @view_type = get_view_type(SESSION_VIEW_TYPE_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @policies }
    end
  end

  def show

    @page_title = @policy.name

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @policy }
    end
  end

  
  def new

    @page_title = 'New Replacement Policy'

    @policy = Policy.new
    @policy.organization = @organization
    @year_list = create_year_list
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @policy }
    end
  end

  def edit
    
  end

  # Copy a policy to a new policy. This could be copying from a parent agency to a member agency or
  # vis versa
  def copy
    
    old_policy_name = @policy.name
    new_policy = @policy.dup
    new_policy.organization = current_user.organization
    new_policy.name = "Copy of " + @policy.name
    new_policy.description = "Copy of " + @policy.description

    new_policy.save

    # now attempt to load the newly created record
    @policy = current_user.organization.policies.find(new_policy.policy_id)
    respond_to do |format|
      if @policy
        format.html { redirect_to edit_policy_url(@policy), :notice => "Policy #{old_policy_name} was successfully copied." }
        format.json { render :json => @policy, :status => :created, :location => @policy }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @policy.errors, :status => :unprocessable_entity }
      end
    end
                          
  end
  
  def create

    @policy = Policy.new(form_params)
    @policy.agency = @organization

    respond_to do |format|
      if @policy.save
        format.html { redirect_to policy_url(@policy), :notice => "Policy #{@policy.name} was successfully created." }
        format.json { render :json => @policy, :status => :created, :location => @policy }
      else
        format.html { render :action => "new" }
        format.json { render :json => @policy.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @policy.update_attributes(form_params)
        format.html { redirect_to policy_url(@policy), :notice => "Policy #{@policy.name} was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @policy.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy

    @policy.destroy

    respond_to do |format|
      format.html { redirect_to policies_url, :notice => "Policy #{@policy.name} was successfully removed." }
      format.json { head :no_content }
    end
  end
  
  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:policy).permit(policy_allowable_params)
  end

  def get_policy
    # See if it is our policy
    @policy = Policy.find(params[:id]) unless params[:id].nil?
    if @policy.nil?
      @policy = Organization.get_typed_organization(@organization).get_policy
    end
    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @policy.nil?
      redirect_to(policies_url, :flash => { :alert => 'Record not found!'})
      return
    end
    
  end
  
  def create_year_list
    a = []
    year = Date.today.year
    (0..12).each do |y|
      a << year + y
    end
    return a
  end
  
  def check_for_cancel
    unless params[:cancel].blank?
      # get the policy, if one was being edited
      if params[:id]
        redirect_to(policy_url(params[:id]))
      else
        redirect_to(policies_url)
      end
    end
  end
end
