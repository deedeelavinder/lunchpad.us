class OrderedItem < ActiveRecord::Base
  resourcify
  belongs_to :available_menu_item
  belongs_to :order
  delegate :menu_item, to: :available_menu_item, allow_nil: true
  delegate :date, to: :available_menu_item, allow_nil: true
  delegate :account, to: :order, allow_nil: true
  delegate :section, to: :account, allow_nil: true
  delegate :vendor, to: :menu_item, allow_nil: true
  after_create :credit_account
  after_update :update_account
  after_destroy :debit_account
  before_destroy :for_future_date?
  default_scope { order(created_at: :asc) }

  validates :available_menu_item_id,
            presence: true

  validates :quantity,
            presence: true

  def subtotal
    quantity * menu_item.price
  end

  def subtotal_dollars
    Money.new(subtotal).to_s
  end

  def self.build_menu(begin_date,end_date)
    available_menu_items = AvailableMenuItem.within_date_range(begin_date,end_date)
    available_menu_items.map { |ami| OrderedItem.new(quantity: 0, available_menu_item_id: ami.id) }
  end

  def copyable_date
    availability_dates = menu_item.available_menu_items.where('date >= ?',self.date.beginning_of_day).order('date ASC').pluck(:date).map(&:to_date)
    return self.date.to_date if availability_dates.count == 1
    max_date = availability_dates.shift
    availability_dates.each do |availability|
      max_date = availability if (availability == max_date + 7) || (vendor.school.off_days.pluck(:date).map(&:to_date).exclude? availability)
      break if availability > max_date + 7 && (vendor.school.off_days.pluck(:date).map(&:to_date).exclude? availability - 7)
    end
    max_date
  end

  def copy(copy_date,order_id)
    return true if vendor.school.off_days.pluck(:date).map(&:to_date).include? copy_date
    ami = menu_item.available_menu_items.where('date >= ? AND date <= ?',copy_date.beginning_of_day,copy_date.end_of_day).first
    OrderedItem.create(available_menu_item_id: ami.id, order_id: order_id, quantity: self.quantity)
  end

  def self.ordered_between(begin_datetime = DateTime.now.beginning_of_month, end_datetime = DateTime.now.end_of_month)
      self.joins(:available_menu_item).where('quantity > ? AND date >= ? AND date <= ?',0,begin_datetime.beginning_of_day,end_datetime.end_of_day)
  end

  private

  def credit_account
    account.increment!(:balance, subtotal)
  end

  def debit_account
    account.decrement!(:balance, subtotal)
  end

  def update_account
    quantities = changes[:quantity]
    change = (quantities[1] - quantities[0]) * menu_item.price
    account.increment!(:balance, change)
  end

  def for_future_date?
    cutoff_date = Date.parse('Monday')
    cutoff_date += 7 if cutoff_date < Date.today
    date >= cutoff_date
  end
end
