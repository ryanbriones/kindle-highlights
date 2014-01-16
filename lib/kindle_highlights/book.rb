require "pg"

require "kindle_highlights/highlight"

module KindleHighlights
  class Book
    attr_accessor :id, :asin, :title, :highlights

    def initialize(id, asin, title)
      @id = id
      @asin = asin
      @title = title
      @highlights = []
    end
    
    def persisted?
      !id.nil?
    end
    
    def save
      return if persisted?
      
      if DB.exec_params("SELECT count(*) FROM books WHERE asin = $1", [@asin]).getvalue(0,0).to_i.zero?
        DB.exec_params("INSERT INTO books (asin, title) VALUES ($1, $2)", [@asin, @title])
      end
      
      @id = DB.exec_params("SELECT id FROM books WHERE asin = $1", [@asin]).getvalue(0,0)
    end
    
    def add_highlight(location, text)
      @highlights << Highlight.new(nil, self, location, text)
    end
  end
end