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
      redirect_to @website
    else
      render :new
    end
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

  private
  def website_params
    params.require(:website).permit(:title, :body)
  end

end
