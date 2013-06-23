#
#  AppDelegate.rb
#  JIRA Glue
#
#  Created by Nick Burwell on 6/22/13.
#  Copyright 2013 Burwell Designs. All rights reserved.
#

class AppDelegate
    attr_accessor :window
    attr_accessor :textFieldKey
    attr_accessor :textFieldOutput
    
    attr_accessor :jira_client
    
    require 'rubygems'
    require 'jira'
    require 'openssl'

    # TODO
    #  * put search on background thread
    #  * ideally do start-up on background thread too..
    #  * put on clipboard
    #  * put on clipboard as HTML
    
    JIRA_BASE_URL = "https://ringrevenue.atlassian.net"
    
    JIRA_CLIENT_OPTIONS = {
    :username        => "development",
    :password        => "6gsvnknFocQ6Te",
    :site            => JIRA_BASE_URL,
    :context_path    => "",
    :auth_type       => :basic,
    :use_ssl         => true,
    :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
    }
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
        
        textFieldOutput.setStringValue("Connecting to JIRA...")
        self.jira_client = JIRA::Client.new(JIRA_CLIENT_OPTIONS)
        textFieldOutput.setStringValue("")
    end
    
    def onButtonClick(sender)
        textFieldOutput.setStringValue("Searching for issue...")
        issue = jira_client.Issue.find(textFieldKey.stringValue)
        
        url = "#{JIRA_BASE_URL}/issues/#{issue.key}"
        key = "#{issue.key}: #{issue.summary}"
        textFieldOutput.setStringValue(key)
    end
    
    def link_to_jql(jql)
        "#{JIRA_BASE_URL}/issues/?jql=#{CGI.escape(jql)}"
    end
end

