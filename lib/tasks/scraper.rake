namespace :scraper do
  require "nokogiri"
  require "open-uri"
  require "csv"

  desc "scrape for players"
  task :get_player_data do

    year = 2013
    header = "name,class,pos,ht,wt,rate,star,school,conf,year\n"
    file = "#{Rails.root}/db/players.csv"
    File.open(file, "w") do |csv|
      csv << header
      
      CSV.foreach("#{Rails.root}/db/schools.csv", :headers => :first_row) do |row|
        url = render_school_url(year, row)
        puts url
        doc = Nokogiri::HTML(open(url))
        table = get_player_table(doc)

        player_data = extract_player_data(table, row["school_id"], row["conf_id"], year)
        
        player_data.each do |player|
          puts player
          csv << player
        end
      end
    end
  end

  desc "scrape for school codes"
  task :get_school_codes do

    year = 2013
    header = "school_name,school_id\n"
    file = "#{Rails.root}/db/school_codes.csv"
    File.open(file, "w") do |csv|
      csv << header

      conferences = ["ACC", "SEC", "BIG12", "BIG10", "PAC12", "MWEST", "AAC"]
      
      conferences.each do |conference|
        url = render_conference_url(year, conference)
        doc = Nokogiri::HTML(open(url))
        table = get_school_table(doc)
        school_data = extract_school_data(table)

        school_data.each do |school|
          puts school
          csv << school
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
    "http://rivals.yahoo.com/footballrecruiting/football/recruiting/commitments/#{year}/#{row["rivals_school_name"]}-#{row["rivals_school_id"]}"
  end

  def render_conference_url(year, school_id)
    "http://rivals.yahoo.com/footballrecruiting/football/recruiting/teamrank/#{year}/#{school_id}/all"
  end

  def get_player_table(doc)
    table_parent = doc.css("#ysr-rankings-container1")
    table_parent.css("table")
  end

  def get_school_table(doc)
    table_parent = doc.css("#ysr-rankings-container")
    table_parent.css("table")
  end

  def extract_player_data(table, school, conf, year)
    rows = get_player_rows(table)
    eligible_rows = rows.select{ |row| row if eligible?(row.css("td.position").text) }
    eligible_rows.map!{ |row| parse_player_row(row, school, conf, year) }
  end

  def extract_school_data(table)
    rows = get_school_rows(table)
    links = rows.map do |row|
      parse_school_row("#{row.css("td").css("a").attr("href").value}")
    end
  end

  def get_player_rows(table)
    table.css("tr")
  end

  def get_school_rows(table)
    table.css("tbody tr")
  end

  def parse_player_row(row, school, conf, year)
    name = row.css("th a")[0].text if row.css("th a")[0].present?
    position = row.css("td.position").text
    height = row.css("td.height").text
    weight = row.css("td.weight").text
    numstars = row.css("td.numstars").text.split(" ")[0]
    rating = row.css("td.rating").text
    "#{name},recruit,#{position},#{height},#{weight},#{rating},#{numstars},#{school},#{conf},#{year}\n"
  end

  def parse_school_row(row)
    school_name = row.split("/")[8].split("-")[0]
    school_id = row.split("/")[8].split("-")[1]
    "#{school_name},#{school_id}\n"
  end

  def eligible?(position)
    eligible_positions = ["QB", "RB", "WR", "TE", "ATH"]
    eligible_positions.include?(position)
  end
end