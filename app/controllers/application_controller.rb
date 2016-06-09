class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  # default page for the application

  def index

  end
  require 'rest_client'
  require 'json'
  def send_email
    @status = 'OK'
    @errors = false
    begin
      params[:emails].reject! { |c| c.blank? }
      unless params[:emails].blank?
        invalid_emails = (params[:emails] & get_suppressions)
        @errors = "#{invalid_emails.join(',')} are suppressed emails,please remove them from your list" unless invalid_emails.blank?
        unless @errors
          RestClient.post "#{APIURL}messages",
                          :from => 'sudheerm16@gmail.com',
                          :to => params[:emails].join(','),
                          :subject => params[:subject],
                          :text => params[:body],
                          'o:campaign' => "#{params[:campaign_id]}"
          RestClient.post "#{APIURL}messages",
                          :from => 'sudheerm16@gmail.com',
                          :to => 'sudheerm16@gmail.com',
                          :subject => "#{params[:campaign_id]} - Campaign List",
                          :text => "#{params[:emails].join(',')} are the previously send emails"
        end
      else
        @errors = 'Please add at least one email to your list'
      end
    rescue Exception => invalid
      @errors = invalid.message
    end

    respond_to do |format|
      format.js { flash[:notice] = 'Emails sent successfully' }
    end
  end

  def get_suppressions
    JSON.parse(RestClient.get "#{APIURL}complaints")['items'] + JSON.parse(RestClient.get "#{APIURL}bounces")['items'] +
        JSON.parse(RestClient.get "#{APIURL}unsubscribes")['items']
  end
end
