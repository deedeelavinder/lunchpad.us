class MenuItemsController < ApplicationController
  before_action :set_menu_item, only: [:show, :edit, :update, :destroy]
  before_action :set_vendor, only: [:new, :create]

  def show
  end

  def new
    @menu_item = @vendor.menu_items.new
  end

  def edit
  end

  def create
    @menu_item = @vendor.menu_items.new(menu_item_params)
    render :new unless @menu_item.save
    redirect_to @vendor, success: 'Menu item was created.'
  end

  def update
    return unless @menu_item.update(menu_item_params)
    redirect_to @menu_item
  end

  def destroy
    @vendor = @menu_item.vendor
    return unless @menu_item.destroy
    redirect_to @vendor, success: 'Menu item was removed.'
  end

  private

  def set_menu_item
    @menu_item = MenuItem.find(params[:id])
  end

  def set_vendor
    @vendor = Vendor.find(params[:vendor_id])
  end

  def menu_item_params
    params.require(:menu_item).permit(:vendor_id, :name, :description, :price)
  end
end
