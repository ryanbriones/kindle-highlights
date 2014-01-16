require "pg"

require "kindle_highlights/book"

module KindleHighlights
  class Highlight
    attr_accessor :id, :location, :text

    def initialize(id, book_or_book_id, location, text)
      @id = id
      @location = location
      @text = text
      
      if book_or_book_id.is_a?(KindleHighlights::Book)
        @book = book_or_book_id
        @book_id = book_or_book_id.id
      else
        @book_id = book_or_book_id
        @book = nil
      end
    end
    
    def persisted?
      !id.nil?
    end
    
    def save
      return if persisted?
      
      if !@book_id && @book.id
        @book_id = @book.id
      end
      
      if DB.exec_params(
        "SELECT count(*) FROM highlights WHERE book_id = $1 AND location = $2",
        [@book_id, location]
      ).getvalue(0,0).to_i.zero?
        DB.exec_params(
          "INSERT INTO highlights (book_id, location, text) VALUES ($1, $2, $3)", 
          [@book_id, location, text]
        )
      end
      
      @id = DB.exec_params(
        "SELECT id FROM highlights WHERE book_id = $1 AND location = $2", 
        [@book_id, location]).getvalue(0,0)
    end
  end
end