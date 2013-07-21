namespace :scraper do
  require "nokogiri"
  require "open-uri"
  require "csv"

  desc "scrape designated site"
  task :run do
    CSV.foreach("#{Rails.root}/db/schools.csv", :headers => :first_row) do |row|
      url = render_url(row)
      doc = Nokogiri::HTML(open(url))
      table = get_table(doc)

      player_data = extract_player_data(table, row["school_id"], row["conf_id"], row["year"])
      player_data.each do |player|
        puts player
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

  def render_url(row)
    "http://rivals.yahoo.com/footballrecruiting/football/recruiting/commitments/#{row["year"]}/#{row["rivals_school_name"]}-#{row["rivals_school_id"]}"
  end

  def get_table(doc)
    table_parent = doc.css("#ysr-rankings-container1")
    table_parent.css("table")
  end

  def get_rows(table)
    table.css("tr")
  end

  def parse_row(row, school, conf, year)
    name = row.css("th a")[0].text if row.css("th a")[0].present?
    position = row.css("td.position").text
    height = row.css("td.height").text
    weight = row.css("td.weight").text
    numstars = row.css("td.numstars").text.split(" ")[0]
    rating = row.css("td.rating").text
    "#{name},#{position},#{height},#{weight},#{rating},#{numstars},#{school},#{conf},#{year}\n"
  end

  def extract_player_data(table, school, conf, year)
    rows = get_rows(table)
    eligible_rows = rows.select{ |row| row if eligible?(row.css("td.position").text) }
    eligible_rows.map!{ |row| parse_row(row, school, conf, year) }
  end

  def eligible?(position)
    eligible_positions = ["QB", "RB", "WR", "TE", "ATH"]
    eligible_positions.include?(position)
  end
end