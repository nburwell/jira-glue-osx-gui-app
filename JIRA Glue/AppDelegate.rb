#
#  AppDelegate.rb
#  JIRA Glue
#
#  Created by Nick Burwell on 6/22/13.
#  Copyright 2013 Burwell Designs. All rights reserved.
#

# TODO
# * Make the 'browser' button a keyboard hot-key
# * Make hot-key configurable in preferences
# * Make browser configurable in preferences


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
    
    JIRA_BASE_URL = "https://ringrevenue.atlassian.net"
    
    JIRA_CLIENT_OPTIONS = {
    :username        => "",
    :password        => "",
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
    
    def onSearchButtonClick(sender)
        labelStatus.setStringValue("")
        textFieldOutput.setStringValue("")
        
        if textFieldKey.stringValue == ""
            labelStatus.setStringValue("Please enter a JIRA key")
            NSLog("nothing to do")
        else
            jiraSearch(textFieldKey.stringValue)
        end
    end
    
    def onBrowserButtonClick(sender)
        script = NSAppleScript.alloc.initWithSource "tell application \"Google Chrome\" to get URL of active tab of front window as string"
        scriptError = nil
        descriptor = script.executeAndReturnError scriptError
        
        if (scriptError)
            NSLog("Error: %@", scriptError)
        else
            url = descriptor.stringValue
            
            if matches = url.match(/ringrevenue.atlassian.net\/browse\/([^?]*)/)
                jiraSearch(matches[1])
            else
                labelStatus.setStringValue("Browser is not viewing a JIRA issue")
            end
        end
    end
    
    def jiraSearch(id)
        labelStatus.setStringValue("Searching for issue...")
        
        queue = Dispatch::Queue.concurrent
        queue.async do
            begin
                issue = jira_client.Issue.find(id)
                
                url = "#{JIRA_BASE_URL}/browse/#{issue.key}"
                key = "#{issue.key}: #{issue.summary}"
                textFieldOutput.setStringValue(key)
                labelStatus.setStringValue("")
                
                if checkboxClipboard.state == NSOnState
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

