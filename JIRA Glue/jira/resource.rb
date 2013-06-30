#
#  issue.rb
#  JIRA Glue
#
#  Adapted from https://github.com/sumoheavy/jira-ruby
#


require 'cgi'

module JIRA
    module Resource
        class VersionFactory < JIRA::BaseFactory ;end
        class Version < JIRA::Base ; end
        
        class ComponentFactory < JIRA::BaseFactory ; end
        class Component < JIRA::Base ; end
        
        class UserFactory < JIRA::BaseFactory ; end
        class User < JIRA::Base
            def self.singular_path(client, key, prefix = '/')
                collection_path(client, prefix) + '?username=' + key
            end
        end
    
        class AttachmentFactory < JIRA::BaseFactory ; end
        class Attachment < JIRA::Base
            has_one :author, :class => JIRA::Resource::User
        end
    
        class IssuetypeFactory < JIRA::BaseFactory ; end
        class Issuetype < JIRA::Base ; end
    
        class PriorityFactory < JIRA::BaseFactory ; end
        class Priority < JIRA::Base ; end

        class StatusFactory < JIRA::BaseFactory ; end
        class Status < JIRA::Base ; end
    
        class ProjectFactory < JIRA::BaseFactory ; end
        class Project < JIRA::Base
            
            has_one :lead, :class => JIRA::Resource::User
            has_many :components
            has_many :issuetypes, :attribute_key => 'issueTypes'
            has_many :versions
            
            def self.key_attribute
                :key
            end
            
            # Returns all the issues for this project
            def issues
                response = client.get(client.options[:rest_base_path] + "/search?jql=project%3D'#{key}'")
                json = self.class.parse_json(response.body)
                json['issues'].map do |issue|
                    client.Issue.build(issue)
                end
            end
        end

        class CommentFactory < JIRA::BaseFactory ; end
        class Comment < JIRA::Base
            belongs_to :issue
            
            nested_collections true
        end

        class WorklogFactory < JIRA::BaseFactory ; end
        class Worklog < JIRA::Base
            has_one :author, :class => JIRA::Resource::User
            has_one :update_author, :class => JIRA::Resource::User, :attribute_key => "updateAuthor"
            belongs_to :issue
            nested_collections true
        end

        class IssueFactory < JIRA::BaseFactory ; end
        class Issue < JIRA::Base
                
            has_one :reporter,  :class => JIRA::Resource::User, :nested_under => 'fields'
            has_one :assignee,  :class => JIRA::Resource::User, :nested_under => 'fields'
            has_one :project,   :nested_under => 'fields'
            
            has_one :issuetype, :nested_under => 'fields'
            
            has_one :priority,  :nested_under => 'fields'
            
            has_one :status,    :nested_under => 'fields'
            
            has_many :components, :nested_under => 'fields'
            
            has_many :comments, :nested_under => ['fields','comment']
            
            has_many :attachments, :nested_under => 'fields', :attribute_key => 'attachment'
            
            has_many :versions, :nested_under => 'fields'
            
            has_many :worklogs, :nested_under => ['fields','worklog']
            
            def self.all(client)
                response = client.get(client.options[:rest_base_path] + "/search")
                json = parse_json(response.body)
                json['issues'].map do |issue|
                    client.Issue.build(issue)
                end
            end

            def self.jql(client, jql)
                url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)
                response = client.get(url)
                json = parse_json(response.body)
                json['issues'].map do |issue|
                    client.Issue.build(issue)
                end
            end

            def respond_to?(method_name)
                if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
                    true
                    else
                    super(method_name)
                end
            end

            def method_missing(method_name, *args, &block)
                if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
                    attrs['fields'][method_name.to_s]
                else
                    super(method_name)
                end
            end
        end

    end # Resource
end # JIRA
