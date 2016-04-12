class UserOrganizationFilter < ActiveRecord::Base

  # Include the unique key mixin
  include TransamObjectKey

  # Callbacks
  after_initialize :set_defaults
  after_save       :require_at_least_one_organization     # validate model for HABTM relationships

  # Clean up any HABTM associations before the asset is destroyed
  before_destroy { :clean_habtm_relationships }

  # Each filter is owned by a specific user
  belongs_to  :user

  # Each filter can have a list of organizations that are included
  has_and_belongs_to_many :organizations, :join_table => 'user_organization_filters_organizations'

  validates   :user_id,       :presence => :true
  validates   :name,          :presence => :true
  validates   :name,          :uniqueness => true
  validates   :description,   :presence => :true

  # Allow selection of active instances
  scope :active, -> { where(:active => true) }
  # sorting rule: 1. first sort ASC based on sort_order; 2. for those without sort_order, sort by name ASC
  scope :sorted, -> { order('sort_order IS NULL, sort_order ASC', :name) }

  # Named Scopes
  scope :system_filters, -> { where('user_id = ? AND active = ?', 1, 1 ) }
  scope :other_filters, -> { where('user_id > ? AND active = ?', 1, 1 ) }

  # List of allowable form param hash keys
  FORM_PARAMS = [
    :user_id,
    :name,
    :description,
    :organization_ids
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns true if this is a system filter
  def system_filter?
    UserOrganizationFilter.system_filters.include? self
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------

  protected

  def require_at_least_one_organization
    if organizations.count == 0
      errors.add(:organizations, "must be selected.")
      return false
    end
  end

  def clean_habtm_relationships
    organizations.clear
  end

  private
  # Set resonable defaults for a new filter
  def set_defaults
    self.active = self.active.nil? ? true : self.active
  end


end