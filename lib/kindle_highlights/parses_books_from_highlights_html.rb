require "nokogiri"

require "kindle_highlights/book"

module KindleHighlights
  class ParsesBooksFromHighlightsHTML
    def initialize(highlights_html)
      @highlights_html = highlights_html
      @parsed_highlights_dom = Nokogiri::HTML(@highlights_html)
    end
    
    def books
      @books ||= begin
        books = []
        
        @parsed_highlights_dom.search(".bookMain").each do |book|
          asin = book.attributes["id"].to_s.split("_").first
          title = book.search(".title").text
  
          books << KindleHighlights::Book.new(nil, asin, title)
        end
      
        books
      end
    end
    
    def add_highlights
      @parsed_highlights_dom.search(".highlightRow:not(.noteOnly)").each do |stuff|
        asin = stuff.search("input[name=asin]").first.attributes["value"].to_s  
        location = CGI.parse(URI.parse(stuff.search(".linkOut").first.attributes["href"]).query)["location"].first
        
        books.detect { |book| book.asin == asin }.tap do |book|
          book.add_highlight(location, stuff.search(".highlight").first.text)
        end
      end
    end
    
    def get_books_with_highlights
      books
      add_highlights
      
      return books
    end
  end
end