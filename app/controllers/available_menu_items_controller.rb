class AvailableMenuItemsController < ApplicationController
  before_action :set_available_menu_item, only: [:destroy]
  def index
    @available_menu_items = AvailableMenuItem.all
  end

  def query
    dates = date_range_params.values.map { |date| Date.parse(date) }
    @available_menu_items = AvailableMenuItem.within_date_range(dates.first,dates.last)
    @orders_not_submitted = {}
    @available_menu_items.each do |item|
      identifier = ('item_' + item.id.to_s)
      @orders_not_submitted[identifier.to_sym] = OrderedItem.new(menu_item_id: item.menu_item_id, delivery_date: item.date, quantity: 0)
    end
  end

  def destroy
    return unless @available_menu_item.destroy
    redirect_to available_menu_item_path
  end

  private

  def date_range_params
    # params.require(:date_range).permit(:begin_date,:end_date)
    { begin_date: '2014-11-17', end_date: '2014-11-18' }
  end

  def set_available_menu_item
    @available_menu_item = AvailableMenuItem.find(params[:id])
  end
end
