require 'open-uri'

class WebsitesController < ApplicationController
  def index
    @websites = Website.all
  end
  def show
    @website = Website.find(params[:id])
  end

  def new
    @website = Website.new
  end

  def create
    @website = Website.new(website_params) #(title: "...", body: "...")

    if @website.save
      @website.save
      redirect_to root_path
    else
      render :new
    end
  end

  def add_domains
    @website = Website.new
  end

  def create_domains


    @website = Website.new(domains_params) #(title: "...", body: "...")
    if @website.save
      render json: @website
      #redirect_to root_path
    else
      render :add_domains
    end

  end

  def load_demo
    @website = Website.insert_all([
                                    { id: 334, domain_name: "google.com", created_at: "2020-12-20 11:28:13.142129", updated_at: "2020-12-20 11:28:13.142129" },
                                    { id: 535, domain_name: "yandex.ru", created_at: "2020-12-20 11:28:13.142129", updated_at: "2020-12-20 11:28:13.142129" }
                                  ])
    redirect_to root_path
  end

  def edit
    @website = Website.find(params[:id])
  end

  def update
    @website = Website.find(params[:id])

    if @website.update(website_params)
      redirect_to @website
    else
      render :edit
    end
  end

  def destroy
    @website = Website.find(params[:id])
    @website.destroy

    redirect_to root_path
  end

  def destroy_all
    @websites = Website.all
    @websites.destroy_all

    redirect_to root_path
  end

  def update_all
    URI.open('https://api.telegram.org/bot1240696416:AAHBIc1sbWcFVFl5StjYYCByiV48VvZDmmo/sendMessage?chat_id=1215881056&text=hi')
  end

  private
  def website_params
    params.require(:website).permit(:domain_name)
  end

  def domains_params
    params.require(:website).permit(:domain_name).yield_self { |x| { id: :id, domain_name: x.values[0], created_at: :created_at, updated_at: :updated_at } }
  end
end
