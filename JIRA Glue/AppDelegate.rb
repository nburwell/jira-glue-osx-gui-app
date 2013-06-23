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
    attr_accessor :labelStatus
    attr_accessor :checkboxClipboard
    
    attr_accessor :jira_client
    
    require 'rubygems'
    require 'jira'
    require 'openssl'

    # TODO
    #  * put search on background thread
    #  * ideally do start-up on background thread too..
    #  X put on clipboard
    #  X put on clipboard as HTML
    
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
        
        self.jira_client = JIRA::Client.new(JIRA_CLIENT_OPTIONS)
        labelStatus.setStringValue("")
    end
    
    def onButtonClick(sender)
        labelStatus.setStringValue("")
        textFieldOutput.setStringValue("")
        
        if textFieldKey.stringValue == ""
            labelStatus.setStringValue("Please enter a JIRA key")
            NSLog("nothing to do")
        else
            labelStatus.setStringValue("Searching for issue...")
            
            begin
                issue = jira_client.Issue.find(textFieldKey.stringValue)
                
                url = "#{JIRA_BASE_URL}/issues/#{issue.key}"
                key = "#{issue.key}: #{issue.summary}"
                textFieldOutput.setStringValue(key)
                labelStatus.setStringValue("")
                
                if checkboxClipboard.state == NSOnState
                    
                    NSLog("copy to clipboard!")
                    
                    pasteBoard = NSPasteboard.generalPasteboard
                    pasteBoard.declareTypes([NSHTMLPboardType, NSStringPboardType], owner: nil)
                    pasteBoard.setString("<a href=\"#{url}\">#{issue.key}</a>: #{issue.summary}", forType: NSHTMLPboardType)
                    pasteBoard.setString("#{key}", forType: NSStringPboardType)
                end
            rescue JIRA::HTTPError => ex
                labelStatus.setStringValue("JIRA issue not found")
            end
        end
    end
end

