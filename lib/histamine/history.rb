# -*- coding: utf-8 -*-
#--
#   Copyright © 2012 Ken Coar
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#++

require('rubygems')
require('histamine/labeling')

module Histamine

  #
  # Class docco
  #
  class History

    include Enumerable
    include Histamine::Labeling

    attr_accessor(:buckets)
    attr_reader(:ordered)

    #
    # @param [Hash] hsh_p
    # @return [void]
    #
    def initialize(hsh_p={})
      #
      # Figure out what the base identity is for this particular
      # History instance.
      #
      cred = self.identify
      @identity = cred[:identity]
      @host = cred[:host]
      @user = cred[:user]
      @buckets = []
      @ordered = {}
      self.import(hsh_p)
    end

    #
    # @param [Array] args_p
    # @yield
    # @return [Array]
    #
    def each(*args_p, &block)
      return @buckets.each(&block)
    end

    #
    # @param [Array<Timebucket>] args_p
    # @return [Array]
    #  (see #import)
    #
    def <<(*args_p)
      result = self.import(:buckets => args_p.flatten.uniq)
    end

    #
    # Return an array of the unique identities represented in this
    # History instance.
    #
    # @return [Array<String>]
    #
    def identities
      results = @ordered.keys.sort
      return results
    end

    #
    # Return an array of History instances, one for each unique
    # identity in the current one.
    #
    # @return [Array<History>]
    #
    def split
      results = @ordered.inject([]) { |memo,(identity,buckets)|
        newinst = self.class.new(:identity => identity)
        newinst.buckets = buckets.dup
        newinst.collate!
        memo << newinst
        memo
      }
      return results
    end

    #
    # @todo
    #   Provide for the merging in of another complete History
    #   instance.  Or should that be a separate #merge method?
    #
    # @param [Hash] hsh_p
    # @return
    #
    def import(hsh_p={})
      cred = self.identify
      if (bkts = hsh_p[:buckets])
        @buckets |= hsh_p[:buckets]
      end
      if (file = hsh_p[:file])
        if (file.kind_of?(String))
          source = File.readlines(file)
        elsif (file.kind_of?(IO))
          source = file.readlines
        end
      end
      if (source = (hsh_p[:string] || hsh_p[:data] || hsh_p[:input]))
        source = source.split(%r![\r\n]+!)
      end
      return self if (source.nil? || source.empty?)

      unless (source.nil?)
        #
        # Add a catch-all bucket for any history commands that don't
        # have a timestamp.
        #
        bucket = Timebucket.new(:time		=> Time.now.localtime,
                                :identity	=> cred[:identity])
        @buckets << bucket
        source.each do |line|
          if (m = line.match(%r!^\#(\d+)$!))
            bucket = Timebucket.new(:time	=> m.captures[0].to_i,
                                    :identity	=> cred[:identity])
            @buckets << bucket
            next
          end
          bucket << line
        end
      end
      self.collate!
      self.winnow
    end

    #
    # Go through all the buckets we have and link them into separate
    # lists by identity.
    #
    # @return [Array<TimeBucket>]
    #   Returns the array of all command buckets we have.
    #
    def collate!
      @buckets = @buckets.sort { |a,b| b.time <=> a.time }
      @ordered = {}
      @buckets.map { |o| o.identity }.uniq.each do |identity|
        @ordered[identity] = @buckets.select { |o| o.identity == identity }
      end
      return @buckets
    end

    #
    # For each identity, go through all the buckets in newest to
    # oldest order, and for each bucket remove any commands that
    # appear in newer ones.
    #
    # @return [void]
    #
    def winnow
      @ordered.each do |ident,bucketlist|
        #
        # Put the bucket of commands for this identity into newest to
        # oldest order.
        #
        bucketlist.replace(bucketlist.sort { |a,b| b.time <=> a.time })
        #
        # Now thin the herd.
        #
        collection = []
        bucketlist.each do |tb|
          tb.commands.replace(tb.commands - collection)
          collection |= tb.commands
        end
        #
        # Get rid of any buckets that have had all of their commands
        # removed.
        #
        @buckets.delete_if { |tb| tb.commands.empty? }
        #
        # And put them back into oldest to newest order again.
        #
        @buckets = @buckets.reverse
      end
      return nil
    end

    #
    # If labels are used, the results will be of the
    # <i><b>intersection</b></i> of their values.  That is, if a
    # username and a particular tag are specified, only results that
    # are labeled with *both* that username *and* that tag will be
    # included.
    #
    # @todo
    #  Strict intersection of tags may not be appropriate; investigate.
    #
    # @param [Hash] hsh_p
    #  includes options as in Timebucket#dump
    # @return [String]
    #
    def dump(hsh_p={})
      cred = Histamine::Labeling.identify(hsh_p)
      pp(cred)
      buckets = @buckets.select { |o|
        match = File.fnmatch(cred[:identity], o.identity)
        match
      }
      results = buckets.map { |o| o.dump }.join("\n") + "\n"
      return results
    end

  end

end
