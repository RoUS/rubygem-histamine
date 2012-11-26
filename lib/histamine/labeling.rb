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

module Histamine

  #
  # Commands are kept together in buckets, grouped by the time at
  # which they were saved.  Each bucket also has an identity (host and
  # username) associated with it.  If no identity is specified when a
  # bucket is created, the identity used is '*:*'.
  #
  module Labeling

    MATCH_ANY_HOST	= '*'
    MATCH_ANY_USER	= '*'
    MATCH_ANY_TAG	= [ '*' ]

    attr_accessor(:tags)

    attr_accessor(:username)
    alias_method(:user, :username)
    alias_method(:user=, :username=)

    attr_accessor(:hostname)
    alias_method(:host, :hostname)
    alias_method(:host=, :hostname=)

    attr_accessor(:identity)

    class << self
      #
      # @param [Hash] hsh_p
      # @return [Hash<Symbol=>String>]
      #   Returns a hash with +:identity+, +:host+, and +:user+ keys.
      #
      def identify(hsh_p={})
        results = {
          :user	=> MATCH_ANY_USER,
          :host	=> MATCH_ANY_HOST,
        }
        if (identity_p = hsh_p[:identity])
          (host, user) = identity_p.to_s.split(%r!:!)
          host = host.to_s
          user = user.to_s
          results[:host] = host unless (host.empty?)
          results[:user] = user unless (user.empty?)
        end
        results[:host] = hsh_p[:hostname] || hsh_p[:host] || MATCH_ANY_HOST
        results[:user] = hsh_p[:username] || hsh_p[:user] || MATCH_ANY_USER
        results[:identity] = results[:host] + ':' + results[:user]
        return results
      end

    end                         # eigenclass Labeling

    def identify
      return Histamine::Labeling.identify(:user	=> self.user,
                                          :host	=> self.host,
                                          :tags	=> self.tags)
    end

    #
    # @return [String] identity
    #
    def identity
      return self.host + ':' + self.user
    end

  end                           # module Labeling

end                             # module Histamine
