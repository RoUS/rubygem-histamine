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
require('time') unless (Time.new.respond_to?(:iso8601))
require('histamine/version')
require('pp')

require('ruby-debug')
Debugger.start

#
# Module docco
#
module Histamine

  #
  # Commands are kept together in buckets, grouped by the time at
  # which they were saved.  Each bucket also has an identity (host and
  # username) associated with it.  If no identity is specified when a
  # bucket is created, the identity used is '*:*'.
  #
  # Imports are always holistic; no buckets are omitted regardless of
  # identity.  Winnowing is restricted to buckets with the same
  # identities.  Exporting includes all buckets with matching
  # identities.  Standard glob matching rules apply.
  #

  #
  # @param [Hash] hsh_p
  # @return [Hash<Symbol=>String>]
  #   Returns a hash with +:identity+, +:host+, and +:user+ keys.
  #
  def identify(hsh_p={})
    results = {
      :user	=> '*',
      :host	=> '*',
    }
    if (identity_p = hsh_p[:identity])
      (host, user) = identity_p.to_s.split(%r!:!)
      host = host.to_s
      user = user.to_s
      results[:host] = host unless (host.empty?)
      results[:user] = user unless (user.empty?)
    end
    results[:host] = hsh_p[:host].to_s if (hsh_p.key?(:host))
    results[:user] = hsh_p[:user].to_s if (hsh_p.key?(:user))
    results[:identity] = results[:host] + ':' + results[:user]
    return results
  end
  module_function(:identify)

  #
  # Class docco
  #
  class Command

    attr_accessor(text)
    attr_accessor(:tags)

    #
    # @param [String] text
    # @param [Array<String>] tags
    # @return [void]
    #
    def initialize(text=nil, *tags)
      @text = text
      @tags = tags
    end

  end                           # class Command

  #
  # Class docco
  #
  class Timebucket

    include Enumerable

    attr_accessor(:time)
    attr_accessor(:host)
    attr_accessor(:user)
    attr_accessor(:commands)

    #
    # @param [Hash] hsh_p
    # @return [void]
    #
    def initialize(hsh_p={})
      if (hsh_p[:time])
        @time = Time.at(hsh_p[:time])
      end
      if (hsh_p[:commands])
        @commands = [ *hsh_p[:commands] ].flatten.uniq
      end
      cred = Histamine.identify(hsh_p)
      @host = cred[:host]
      @user = cred[:user]
      @commands ||= []
    end

    #
    # @return [String] identity
    #
    def identity
      return @host + ':' + @user
    end

    #
    # @param [Array] args_p
    # @yield
    # @return [Array]
    #
    def each(*args_p, &block)
      return @commands.send(:each, *args_p, &block)
    end

    #
    # @yield
    # @return [Array]
    #
    def sort(&block)
      results = @commands.send(:sort, &block)
      return results
    end

    #
    # @yield
    # @return [Array]
    #
    def sort!(&block)
      @commands = self.sort(&block)
      return self
    end

    #
    # @param [TimeBucket] other_bucket
    # @return [Boolean]
    #
    def ==(other_bucket)
      results = ((other_bucket.time == self.time) \
                 && (other_bucket.sort ==self.sort))
      return results
    end

    #
    # @param [String, Array<String>] appendee_p
    # @return [Array]
    #
    def <<(appendee_p)
      appendee = [ appendee_p ].flatten - @commands
      return @commands.push(*appendee)
    end

    #
    # @param [Hash] options
    # @return [String]
    #
    def dump(options={})
      results = [ "##{self.time.to_i}" ] + @commands
      return results.join("\n")
    end

    #
    # @param [Symbol] mname_sym
    # @param [Array] args_p
    # @return [Object]
    #
    def method_missing(mname_sym, *args_p)
      pp([ mname_sym, args_p ])
      if ((mname_sym != :inspect) && @commands.respond_to?(mname_sym))
        return @commands.send(mname_sym, *args_p)
      end
      return super
    end

  end

  #
  # Class docco
  #
  class History

    include Enumerable

    attr_accessor(:identity)
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
      cred = Histamine.identify(hsh_p)
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
      return @commands.send(:each, *args_p, &block)
    end

    #
    # @param [Array<Timebucket>] args_p
    # @return [Array]
    #  (see #import)
    #
    def <<(*args_p)
      result = self.import(:buckets => args_p)
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
      cred = Histamine.identify(hsh_p)
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

      #
      # Add a catch-all bucket for any history commands that don't
      # have a timestamp.
      #
      bucket = Timebucket.new(:time	=> Time.now.localtime,
                              :identity	=> cred[:identity])
      @buckets << bucket
      source.each do |line|
        if (m = line.match(%r!^\#(\d+)$!))
          bucket = Timebucket.new(:time		=> m.captures[0].to_i,
                                  :identity	=> cred[:identity])
          @buckets << bucket
          next
        end
        bucket << line
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
    # @param [Hash] hsh_p
    #  includes options as in Timebucket#dump
    # @return [String]
    #
    def dump(hsh_p={})
      cred = Histamine.identify(hsh_p)
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
