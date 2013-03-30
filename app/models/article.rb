class Article < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  belongs_to :editor, class_name: "User"
  has_and_belongs_to_many :tags
  has_many :revisions

  attr_reader :tag_tokens

  before_validation :generate_slug
  before_save :create_revision

  validates :slug, uniqueness: true, presence: true

  def self.text_search(query)
    if query.present?
      where("title ILIKE :q OR content ILIKE :q", q: "%#{query}%").order('title ASC')
    else
      order(updated_at: :desc)
    end 
  end

  def self.ordered_fresh
    all.order(updated_at: :desc).limit(20)
  end

  def fresh?
    created_at >= 7.days.ago || updated_at >= 7.days.ago
  end

  def stale?
    created_at < 3.months.ago && updated_at < 3.months
  end

  def tag_tokens=(tokens)
    self.tag_ids = Tag.ids_from_tokens(tokens)
  end

  def to_s
    title
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug ||= title.parameterize
  end

  def create_revision
    revision = revisions.build(editor: editor || author, content: content)
    revision.save!
  end
end