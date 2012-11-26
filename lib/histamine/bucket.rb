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
require('histamine/command')

module Histamine

  #
  # Class docco
  #
  class Timebucket

    include Enumerable
    include Histamine::Labeling

    attr_accessor(:time)

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
      cred = Histamine::Labeling.identify(hsh_p)
      self.host = cred[:host]
      self.user = cred[:user]
      self.commands ||= []
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

  end                           # class Timebucket

end                             # module Histamine
