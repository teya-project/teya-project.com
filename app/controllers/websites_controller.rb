require 'open-uri'
# gems for rkn check
require 'json'
require 'csv'
require 'colorize'
require 'idna'

class WebsitesController < ApplicationController

  logger = Rails.logger

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

    @website = Website.new(domains_params)
    domain_names = domains_params[:domain_name].split("\r\n").reject { |x| x == "" }.uniq
    domain_names.each do |domain_name|

      @website = Website.insert_all( [
                                       { id: :id, domain_name: "#{Idna.to_ascii(domain_name)}", created_at: DateTime.now, updated_at: DateTime.now, rkn_status: FALSE, rkn_check_ignore: FALSE }
                                     ])
    end
    redirect_to root_path

  end

  def load_demo
    @website = Website.insert_all([
                                    {
                                      "id": 1,
                                      "created_at": "2020-12-22 20:00:47.000",
                                      "updated_at": "2020-12-22 20:00:50.000",
                                      "domain_name": "google.com",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 2,
                                      "created_at": "2020-12-22 20:01:12.000",
                                      "updated_at": "2020-12-22 20:01:14.000",
                                      "domain_name": "yandex.ru",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 3,
                                      "created_at": "2020-12-22 20:01:46.000",
                                      "updated_at": "2020-12-22 20:01:50.000",
                                      "domain_name": "1xbet.com",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 4,
                                      "created_at": "2020-12-22 20:02:34.000",
                                      "updated_at": "2020-12-22 20:02:36.000",
                                      "domain_name": "joycasino.com",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 5,
                                      "created_at": "2020-12-22 20:02:34.000",
                                      "updated_at": "2020-12-22 20:02:36.000",
                                      "domain_name": "casinoblog.appspot.com",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 6,
                                      "created_at": "2020-12-22 20:02:34.000",
                                      "updated_at": "2020-12-22 20:02:36.000",
                                      "domain_name": "xn----7sbvehvh1d.com",
                                      "rkn_status": false,
                                      "rkn_check_ignore": false
                                    }
                                  ])
    redirect_to root_path

  end

  def edit
    @website = Website.find(params[:id])
  end

  def rkn_ignore
    @website = Website.find(params[:id])
    if @website.rkn_check_ignore == true
      @website.update(rkn_check_ignore: false)
    else
      @website.update(rkn_check_ignore: true)
    end
    #render json: @website.rkn_check_ignore
    redirect_to root_path
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

  def load_dump
    @dump_path = './tmp/rkn_check/dump.csv'

    # Проверяем актуальность дампа банов
    @saved_dump_date = File.read('./tmp/rkn_check/dump_date.txt')

    open('./tmp/rkn_check/dump_date.txt', 'wb') do |file|
      last_dump_date = URI.open('https://api.github.com/repos/zapret-info/z-i/commits?path=dump.csv&page=1&per_page=1').read
      date_hash = JSON.parse(last_dump_date)
      @date = date_hash[0]['commit']['author']['date']
      if @saved_dump_date == @date
        file << @saved_dump_date
        logger.info "Используется актуальная версия дампа банов".green
        @updated = false
      else
        file << @date
        @updated = true
      end
    end

    # download dump if commit was updated
    if @updated == true
      open(@dump_path, 'wb') do |file|
        file << URI.open('https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv').read.encode("ISO-8859-1", invalid: :replace, undef: :replace, :quote_char => ':|')
        logger.info "Дамп банов обновлен".green
      end
    end

    ### generate banned domain list
    banned_domains_list = []
    CSV.foreach(@dump_path, "r:bom|ISO-8859-1", :quote_char => '|', liberal_parsing: true) {|row| banned_domains_list << row[0].to_s.split(';')[1]}
    banned_domains_list = banned_domains_list.reject { |x| (x == "")||(x == nil)}
    @banned_domains = banned_domains_list.map { |x| x.gsub("*.", "")}
  end

  def telegram_message(type, domain)
    domain = Idna.to_unicode(domain)
    case type
    when 'rkn'
      URI.open("https://api.telegram.org/bot1240696416:AAHBIc1sbWcFVFl5StjYYCByiV48VvZDmmo/sendMessage?chat_id=1215881056&text=%F0%9F%9A%AB+#{CGI.escape(domain)}+%D0%B2%20%D0%B1%D0%B0%D0%BD%D0%B5%20%D0%A0%D0%9A%D0%9D")
      puts "Забаненный домен #{domain} отправлен в тг".red
      sleep(1)
    when 'expired'
      # nothing
    else
      # nothing
    end
  end

  def rkn_check
    load_dump
    Website.where(domain_name: @banned_domains, rkn_check_ignore: 0).update(rkn_status: true)
    @my_banned_domains = []
    Website.where(rkn_status: 1, rkn_check_ignore: 0).map do |x|
      @my_banned_domains << x.domain_name
    end
    @my_banned_domains.each do |domain|
      telegram_message('rkn', domain)
    end
    logger.info "Забаненные домены отправлены в телеграм".green
  end



  def update_all
    rkn_check
    redirect_to root_path
  end

  private
  def website_params
    params.require(:website).permit(:domain_name, :rkn_status)
  end

  def domains_params
    params.require(:website).permit(:domain_name, :rkn_status, :rkn_check_ignore)
  end
end
