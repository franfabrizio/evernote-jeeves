require "evernote/jeeves/version"

require 'evernote-thrift'
require 'digest/md5'
require 'pp'
require 'yaml'
require 'sanitize'
require 'optparse'
require 'ostruct'

module Evernote
  module Jeeves
    class JeevesOptionsParser

      def self.parse(args)
        options = OpenStruct.new
        #defaults
        options.verbose = FALSE
        options.search = 'TODO'
        options.days = 7

        opts_parser = OptionParser.new do |opts|
          opts.banner = "Usage: jeeves.rb [options]"

          opts.on("-v", "--verbose", "Run verbosely") do |v|
            options.verbose = v
          end

          opts.on("-s", "--search s", String, "Search string to look for in notes.") do |s|
            options.search = s
          end

          opts.on("-d", "--days N", Integer, "Number of days in the past to search.") do |d|
            options.days = d
          end

          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end

        opts_parser.parse!(args)
        options
      end
    end

    class JeevesRunner
      def run
        options = JeevesOptionsParser.parse(ARGV)

        # get the authToken from config
        config = YAML.load_file(File.join(File.dirname(__FILE__),"../../config/config.yml"))
        authToken = config["config"]["authToken"]

        # Since this app only accesses your own Evernote account, we can use a developer token
        # that allows you to access your own Evernote account and skip OAuth authentication.
        # To get a developer token, visit https://sandbox.evernote.com/api/DeveloperToken.action

        if authToken == "your developer token"
        puts "Please fill in your developer token"
        puts "To get a developer token, visit https://sandbox.evernote.com/api/DeveloperToken.action"
        exit(1)
        end

        # Initial development can be performed on Evernote's sandbox server. It requires a separate
        # account and authToken.  To switch to using the sandbox server, change "www.evernote.com" to
        # "sandbox.evernote.com" and replace your developer token above with a sandbox token.
        #evernoteHost = "sandbox.evernote.com"
        evernoteHost = "www.evernote.com"
        userStoreUrl = "https://#{evernoteHost}/edam/user"

        userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
        userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
        userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)

        # Verify your Evernote gem is up to date
        versionOK = userStore.checkVersion("Evernote EDAM (Ruby)",
                                           Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
                                           Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
        raise RuntimeError, "API version out of date" unless versionOK

        # Get the URL used to interact with the contents of the user's account
        # When your application authenticates using OAuth, the NoteStore URL will
        # be returned along with the auth token in the final OAuth request.
        # In that case, you don't need to make this call.
        noteStoreUrl = userStore.getNoteStoreUrl(authToken)

        noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
        noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
        noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

        # search notes
        noteFilter = Evernote::EDAM::NoteStore::NoteFilter.new
        # 2 == sort results by updated
        noteFilter.order = 2
        # newest first
        noteFilter.ascending = FALSE
        noteFilter.words = "updated:day-#{options.days} #{options.search}"

        # We want our search results to return title, notebook GUID, and updated date
        spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
        spec.includeTitle = true
        spec.includeNotebookGuid = true
        spec.includeUpdated = true

        # we limit to 100 results to avoid craziness
        noteList = noteStore.findNotesMetadata(authToken,noteFilter,0,100, spec)

        # time to display the results
        if options.verbose
          puts "There are #{noteList.totalNotes} matching notes."
          puts
        end

        noteList.notes.each do |note|
          # display note metadata
          puts "#{note.title} (#{Time.at(note.updated/1000).strftime("%m/%d/%y")}, #{noteStore.getNotebook(authToken, note.notebookGuid).name})"
          # retrieve the note - just the contents, don't need other resources
          doc = noteStore.getNote(authToken, note.guid, true, false, false, false).content
          # look for the search string in this note's content, line-by-line
          doc.lines.each do |line|
            if line[/#{options.search}/i]
              # indentation hack
              puts "  " + Sanitize.clean(line).strip
            end
          end
          puts
        end
      end
    end
  end
end
