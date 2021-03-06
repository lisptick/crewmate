# -*- encoding : utf-8 -*-
# A User model describes an actual user, with his password and personal info.
# A Person model describes the relationship of a User that follows a Project.

class Person < ActiveRecord::Base
  include Immortal

  belongs_to :user
  belongs_to :project
  belongs_to :source_user, :class_name => 'User'
  has_many :tasks, :foreign_key => 'assigned_id', :dependent => :nullify

  after_create :log_create
  after_destroy :log_delete, :cleanup_after

  #  validates_uniqueness_of :user, :scope => :project
  validates_presence_of :user, :project   # Make sure they both exist and are set
  validates_inclusion_of :role, :in => 0..3
  validates_uniqueness_of :project_id, :scope => :user_id

  serialize :permissions

  ROLES = {:observer => 0, :commenter => 1, :participant => 2, :admin => 3}
  PERMISSIONS = [:view, :edit, :delete, :all]

  scope :admins, lambda{
    where(:role => ROLES[:admin])
  }

  scope :from_unarchived, lambda{
    joins(:project).where(:projects => {:archived => false})
  }

  scope :by_login, lambda { |login|
    includes(:user).where(:users => {:login => login})
  }

  scope :in_alphabetical_order, lambda {
    includes(:user).order('users.first_name ASC')
  }

  attr_accessible :role, :permissions

  def owner?
    project.owner?(user)
  end

  def role_name
    ROLES.index(role)
  end

  def to_s
    name
  end

  def name
    user.name
  end

  def short_name
    user.short_name
  end

  def login
    user.login
  end

  def log_create
    # for a new project, we log create_project, not create_person
    project.log_activity(self, 'create', user_id) unless project.user == user
    # promote the project owner to admin
    update_attribute :role, ROLES[:admin] if project.user == user
  end

  def self.users_from_projects(projects)
    user_ids = Person.where(:project_id => projects.map(&:id)).uniq
    User.select('id, login, first_name, last_name').where(:id => user_ids).sort_by(&:name)
  end

  def self.user_names_from_projects(projects, current_user = nil)
    project_ids = Array.wrap(projects).map(&:id)
    current_user_id = current_user.try(:id).to_i

    select("people.project_id, people.user_id, users.login, users.first_name, users.last_name, people.id, users.id")
      .joins(:project).joins(:user)
      .where("people.project_id IN (?) AND (people.deleted IS NULL OR people.deleted = ?)", project_ids, false)
      .order("users.id = #{current_user_id} DESC, users.login")
  end

  def user
    @user ||= user_id ? User.with_deleted.find_by_id(user_id) : nil
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.person :id => id do
      xml.tag! 'user-id', user.id
      xml.tag! 'username', user.login
      xml.tag! 'role', role
    end
  end

  def to_api_hash(options = {})
    base = {
      :id => id,
      :user_id => user_id,
      :source_user_id => source_user_id,
      :role => role
    }

    base[:type] = self.class.to_s if options[:emit_type]

    if Array(options[:include]).include? :user
      base[:user] = {
        :username => user.login,
        :first_name => user.first_name,
        :last_name => user.last_name,
        :avatar_url => user.avatar_or_gravatar_url(:thumb)
      }
    end

    base
  end

  def to_json(options = {})
    to_api_hash(options).to_json
  end

  protected

  def log_delete
    project.log_activity(self, 'delete')
  end

  def cleanup_after
    user.remove_recent_project(project)
    user.tasks_counts_update
  end
end
