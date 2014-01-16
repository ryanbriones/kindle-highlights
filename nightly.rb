require "uri"
require "pg"
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

db_uri = URI.parse(ENV["DATABASE_URL"] || "postgres://localhost:5432/kindle_highlights_dev")
conn = PG.connect(
  db_uri.host, 
  db_uri.port, 
  nil, 
  nil, 
  db_uri.path[1..-1], 
  db_uri.user,
  db_uri.password)

Capybara.current_driver    = :poltergeist
Capybara.javascript_driver = :poltergeist

Capybara.run_server = false

module MyModule
  extend Capybara::DSL

  def self.highlights!
    page.driver.headers = { "User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }
    
    visit("http://kindle.amazon.com")
    click_link("Guest")
    
    fill_in("My e-mail address is:", :with => ENV["KINDLE_USERNAME"])
    fill_in("password", :with => ENV["KINDLE_PASSWORD"])
    click_on("signInSubmit")
        
    click_link("Your Highlights")
    current_html = page.html
    
    loop do
      page.execute_script("window.scrollTo(0, 10000000)");
      sleep(5)
      scrolled_html = page.html
      if current_html == scrolled_html
        break
      end
      
      current_html = scrolled_html
    end
    
    return current_html
  end
end

html = if ENV["HIGHLIGHTS_CACHE"]
  File.read(ENV["HIGHLIGHTS_CACHE"])
else
  MyModule.highlights!
end

books = {
}

doc = Nokogiri::HTML(html)
doc.search(".bookMain").each do |book|
  asin = book.attributes["id"].to_s.split("_").first
  title = book.search(".title").text
  
  books[asin] = {:title => title}
end

doc.search(".highlightRow:not(.noteOnly)").each do |stuff|
  asin = stuff.search("input[name=asin]").first.attributes["value"].to_s
  books[asin][:highlights] ||= []
  
  location = CGI.parse(URI.parse(stuff.search(".linkOut").first.attributes["href"]).query)["location"].first

  books[asin][:highlights] << {
    :text => stuff.search(".highlight").first.text,
    :location => location
  }
end

books.each do |asin, other|
  title = other[:title]
  if conn.exec_params("SELECT count(*) FROM books WHERE asin = $1", [asin]).getvalue(0,0).to_i.zero?
    conn.exec_params("INSERT INTO books (asin, title) VALUES ($1, $2)", [asin, title])
  end
  book_id = conn.exec_params("SELECT id FROM books WHERE asin = $1", [asin]).getvalue(0,0)
  
  other[:highlights].each do |hl|
    if conn.exec_params(
      "SELECT count(*) FROM highlights WHERE book_id = $1 AND location = $2",
      [book_id, hl[:location]]
    ).getvalue(0,0).to_i.zero?
      conn.exec_params(
        "INSERT INTO highlights (book_id, location, text) VALUES ($1, $2, $3)", 
        [book_id, hl[:location], hl[:text]]
      )
    end
  end
end

# res = conn.exec("
#   SELECT title, location, text
#   FROM highlights h
#   INNER JOIN books b ON b.id = h.book_id
#   ORDER BY RANDOM()
#   LIMIT 1")
# res.each do |row|
#   puts row["text"]
#   puts "\t#{row["title"]} (#{row["location"]})"
# end