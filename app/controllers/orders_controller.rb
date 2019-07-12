class OrdersController < ApplicationController
  before_action :authenticate_user!, only: [:create, :show, :pay_with_alipay, :pay_with_wechat]
  before_action :confirm_user_order_belongs_self, only: [:show, :pay_with_alipay, :pay_with_wechat]

  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = current_cart.total_price

    if @order.save
        current_cart.cart_items.each do |cart_item|
          product_list = ProductList.new
          product_list.order = @order
          product_list.product_name = cart_item.product.title
          product_list.product_price = cart_item.product.price
          product_list.quantity = cart_item.quantity
          product_list.save
        end

        current_cart.clean!
        #OrderMailer.notify_order_placed(@order).deliver!


        redirect_to order_path(@order.token)
    else
      render 'carts/checkout'
    end
  end

  def show
    @order = Order.find_by_token(params[:id])
    @product_lists = @order.product_lists
  end

  def pay_with_alipay
    @order = Order.find_by_token(params[:id])
    @order.set_payment_with!("alipay")
    # @order.pay!
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用支付宝支付成功"
  end

  def pay_with_wechat
    @order = Order.find_by_token(params[:id])
    @order.set_payment_with!("wechat")
    # @order.pay!
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用微信支付成功"
  end

  def apply_to_cancel
    @order = Order.find_by_token(params[:id])
    # OrderMailer.apply_cancel(@order).deliver!
    flash[:notice] = "已提交申请"
    redirect_to :back
  end

  private

  def order_params
    params.require(:order).permit(:billing_name, :billing_address, :shipping_name, :shipping_address)
  end

  def confirm_user_order_belongs_self
    @order = Order.find_by_token(params[:id])
    if @order.user != current_user
      redirect_to root_path, alert: '订单不存在'
    end
  end

end