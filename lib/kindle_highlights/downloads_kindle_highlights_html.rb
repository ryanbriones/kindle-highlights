require "capybara"
require "capybara/dsl"
require "capybara/poltergeist"

Capybara.current_driver    = :poltergeist
Capybara.javascript_driver = :poltergeist

Capybara.run_server = false

module KindleHighlights
  class DownloadsKindleHighlightsHTML
    class SecurityQuestionsError < RuntimeError; end
    
    include Capybara::DSL
    
    def initialize(kindle_username, kindle_password)
      @kindle_username = kindle_username
      @kindle_password = kindle_password
      @highlights_html = ""
      @last_highlights_html = ""
      @logged_in = false
      
      page.driver.headers = { "User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" }
    end
    
    def login
      return if @logged_in
      
      visit("http://kindle.amazon.com")
      click_link("Guest")
    
      fill_in("My e-mail address is:", :with => @kindle_username)
      fill_in("password", :with => @kindle_password)
      click_on("signInSubmit")
      
      if page.html.include?("security questions")
        if block_given?
          yield(self)
        else
          raise SecurityQuestionsError, 
            "There was an issue logging in. You will need to inspect the HTML and create manually answer the security questions"
        end
      end
      
      if page.html.include?("Your Highlights")
        @logged_in = true
      end
    end
    
    def fetch_initial_highlights
      visit("http://kindle.amazon.com")
      click_link("Your Highlights")
      @highlights_html = page.html
    end
    
    def fetch_more_highlights
      @last_highlights_html = @highlights_html
      page.execute_script("window.scrollTo(0, 10000000)")
      sleep(5)
      @highlights_html = page.html
    end
    
    def end_of_highlights?
      @highlights_html == @last_highlights_html
    end
    
    def get_all_highlights
      login
      fetch_initial_highlights
      loop do
        fetch_more_highlights
        break if end_of_highlights?
      end
      
      @highlights_html
    end
  end
end