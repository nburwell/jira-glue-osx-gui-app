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

NSLog("Launching JIRA Glue!")


class AppDelegate
    attr_accessor :window
    attr_accessor :textFieldKey
    attr_accessor :textFieldOutput
    attr_accessor :labelStatus
    attr_accessor :progressBar
    attr_accessor :checkboxClipboard
    
    attr_accessor :jira_client
    attr_accessor :config
    
    require 'rubygems'
    require 'json'
    require 'net/https'
    require 'hotkeys'
    
    JIRA_BASE_URL = "https://ringrevenue.atlassian.net"
    
    
    def observeValueForKeyPath(keyPath, ofObject:id, change:change, context:context)
        login_to_jira
    end
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
        
        self.config = NSUserDefaults.standardUserDefaults
        self.config.addObserver(self,
                                forKeyPath: "jira_username",
                                options: NSKeyValueObservingOptionNew,
                                context: nil)
        
        self.config.addObserver(self,
                                forKeyPath: "jira_password",
                                options: NSKeyValueObservingOptionNew,
                                context: nil)
        
        login_to_jira

        @hotkeys = HotKeys.new
        @hotkeys.addHotString("J+CONTROL") do
            getIssueFromBrowser()
        end
    end
    
    def login_to_jira
        labelStatus.setStringValue("Connecting to JIRA...")
        
        queue = Dispatch::Queue.concurrent
        queue.async do
            jira_client_options = {
                :username        => self.config.stringForKey("jira_username"),
                :password        => self.config.stringForKey("jira_password"),
                :site            => JIRA_BASE_URL,
                :context_path    => "",
                :auth_type       => :basic,
                :use_ssl         => true,
                :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
            }

            self.jira_client = JIRA::Client.new(jira_client_options)
            labelStatus.setStringValue("")
            progressBar.stopAnimation(self)
        end
    end
    
    def onSearchButtonClick(sender)
        labelStatus.setStringValue("")
        textFieldOutput.setStringValue("")
        
        if textFieldKey.stringValue == ""
            labelStatus.setStringValue("Please enter a JIRA key")
            NSLog("Nothing entered")
        else
            jiraSearch(textFieldKey.stringValue)
        end
    end
    
    def onBrowserButtonClick(sender)
        getIssueFromBrowser()
    end
    
    def jiraSearch(id)
        labelStatus.setStringValue("Searching for issue...")
        progressBar.startAnimation(self)
        
        queue = Dispatch::Queue.concurrent
        queue.async do
            begin
                if id.match(/\A\d/)
                    project_key = self.config.stringForKey("default_project")
                    id = "#{project_key}-#{id}"
                end
                issue = jira_client.Issue.find(id)
                
                url = "#{JIRA_BASE_URL}/browse/#{issue.key}"
                key = "#{issue.key}: #{issue.summary}"
                textFieldOutput.setStringValue(key)
                labelStatus.setStringValue("")
                progressBar.stopAnimation(self)
                
                if checkboxClipboard.state == NSOnState
                    pasteBoard = NSPasteboard.generalPasteboard
                    pasteBoard.declareTypes([NSHTMLPboardType, NSStringPboardType], owner: nil)
                    pasteBoard.setString("<a href=\"#{url}\">#{issue.key}</a>: #{issue.summary}", forType: NSHTMLPboardType)
                    pasteBoard.setString("#{key}", forType: NSStringPboardType)
                end
            rescue JIRA::HTTPError => ex
                if ex.message == "Unauthorized"
                    labelStatus.setStringValue("Could not log into JIRA. Update app preferences.")
                else
                    labelStatus.setStringValue("JIRA issue not found.")
                end
                progressBar.stopAnimation(self)
            end
        end
    end
    
    private
    
    def getIssueFromBrowser
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
end
