namespace :scraper do
  require "nokogiri"
  require "open-uri"
  require "csv"

  desc "scrape for players"
  task :get_player_data do
    recruit_year = 2022
    header = "name,class,pos,rate,star,school,conf,year\n"
    file = "#{Rails.root}/db/2022_players_acc.csv"
    File.open(file, "w") do |csv|
      csv << header

      CSV.foreach("#{Rails.root}/db/acc_schools.csv", :headers => :first_row) do |row|
        sleep(rand(3..10))
        url = render_school_url(recruit_year, row)
        puts url

        doc = Nokogiri::HTML(URI.open(url))
        player_data = get_player_data(doc)

        player_data.each do |player|
          if eligible?(player["position_group_abbreviation"]) && player["year"] == recruit_year
            player_details = parse_player_row(player, row["school_id"], row["conf_id"], recruit_year)
            puts player_details
            csv << player_details
          end
        end
      end
    end
  end

  desc "test something"
  task :test do
    # eligible_positions = ["QB", "RB", "WR", "TE", "ATH"]
    # position = "QB"
    # puts "yes" if eligible_positions.include?(position)
  end

  private

  def render_school_url(year, row)
    "https://#{row["rivals_school_name"]}.rivals.com/commitments/football/#{year}/"
  end

  def get_player_data(doc)
    JSON.parse(doc.css("rv-commitments").attr("prospects").value)
  end

  def parse_player_row(player, school, conf, year)
    name = player["name"]
    position = player["position_group_abbreviation"]
    numstars = player["stars"]
    rating = player["rivals_rating"]
    "#{name},recruit,#{position},#{rating},#{numstars},#{school},#{conf},#{year}\n"
  end

  def eligible?(position)
    eligible_positions = ["QB", "RB", "WR", "TE", "ATH"]
    eligible_positions.include?(position)
  end
end
