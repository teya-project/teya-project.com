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
    domains_collection = domain_names.each do |domain_name|

      @website = Website.insert_all( [
                                       { id: :id, domain_name: "#{domain_name}", created_at: DateTime.now, updated_at: DateTime.now, rkn_status: FALSE, rkn_check_ignore: FALSE }
                                     ])
    end
    #render plain: domains_collection
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
                                      "rkn_status": true,
                                      "rkn_check_ignore": false
                                    },
                                    {
                                      "id": 4,
                                      "created_at": "2020-12-22 20:02:34.000",
                                      "updated_at": "2020-12-22 20:02:36.000",
                                      "domain_name": "joycasino.com",
                                      "rkn_status": true,
                                      "rkn_check_ignore": true
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

  def rkn_check(my_domains, ignored_domains)
    @my_domains = my_domains
    @ignored_domains = ignored_domains
    ### load dump
    @dump_path = './tmp/rkn_check/dump.csv'
    # Файлы из переменных ниже рекомендуется создать вручную, воспользовавшись sample-файлами

    @tg_token = './tmp/rkn_check/tg_token.txt'
    @chat_id_path = './tmp/rkn_check/chat_id.txt'

    # Проверяем актуальность дампа банов
    @saved_dump_date = File.read('./tmp/rkn_check/dump_date.txt')

    open('./tmp/rkn_check/dump_date.txt', 'wb') do |file|
      last_dump_date = URI.open('https://api.github.com/repos/zapret-info/z-i/commits?path=dump.csv&page=1&per_page=1').read
      date_hash = JSON.parse(last_dump_date)
      @date = date_hash[0]['commit']['author']['date']
      unless @saved_dump_date == @date
        file << @date
        @updated = true
      else
        file << @saved_dump_date
        logger.info "Используется актуальная версия дампа банов".green
        @updated = false
      end
    end

    # Грузим дамп банов, если дата последнего коммита изменилась
    if @updated == true
      open(@dump_path, 'wb') do |file|
        file << URI.open('https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv').read.encode("ISO-8859-1", invalid: :replace, undef: :replace, :quote_char => ':|')
        logger.info "Дамп банов обновлен".green
      end
    end
    ### genereta banned domain list
    banned_domains_list = []
    CSV.foreach(@dump_path, "r:bom|ISO-8859-1", :quote_char => '|', liberal_parsing: true) {|row| banned_domains_list << row[0].to_s.split(';')[1]}
    banned_domains_list = banned_domains_list.reject { |x| (x == "")||(x == nil)}
    @banned_domains = banned_domains_list.map { |x| x.gsub("*.", "")}

    ### load my domains

    @my_domains = @my_domains.map { |x| x.gsub("\n", "")}
    @my_domains = @my_domains.reject { |x| (x == "")||(x == nil)}
    @my_domains = @my_domains.map { |x| Idna.to_ascii(x)}

    ### load ignored domains
    @my_ignored_domains = @ignored_domains
    @my_ignored_domains = @my_ignored_domains.map { |x| x.gsub("\n", "")}
    @my_ignored_domains = @my_ignored_domains.reject { |x| (x == "")||(x == nil)}
    @my_ignored_domains = @my_ignored_domains.map { |x| Idna.to_ascii(x)}

    ### run checking
    @checking_domains = @my_domains - @my_ignored_domains
    @my_banned_domains = @checking_domains & @banned_domains
    @my_banned_domains_unicode = @my_banned_domains.map { |x| Idna.to_unicode(x)}
    logger.info "Домены в бане: #{@my_banned_domains_unicode}".red

    ### telegram message
    token = File.read(@tg_token)
    chat_id = File.read(@chat_id_path)
    message = @my_banned_domains_unicode.each do |x|
      URI.open("https://api.telegram.org/bot#{token}/sendMessage?chat_id=#{chat_id}&text=%F0%9F%9A%AB+#{CGI.escape(x)}+was+banned+from+RKN")
      puts "Забаненный домен #{x} отправлен в тг".red
      #sleep(3)
    end
    logger.info "Забаненные домены отправлены в телеграм".green if @my_banned_domains.length > 0
  end

  def update_all

    my_domains = Website.all.pluck(:domain_name)
    ignored_domains = Website.all.where(rkn_check_ignore: 1).pluck(:domain_name)
    rkn_check(my_domains, ignored_domains)
    #render plain: ignored_domains
  end

  private
  def website_params
    params.require(:website).permit(:domain_name, :rkn_status)
  end

  def domains_params
    params.require(:website).permit(:domain_name, :rkn_status, :rkn_check_ignore)
  end
end
