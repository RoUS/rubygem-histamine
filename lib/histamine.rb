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
require('pp')

require('ruby-debug')
Debugger.start

#
# Module docco
#
module Histamine

  #
  # Imports are always holistic; no buckets are omitted regardless of
  # identity.  Winnowing is restricted to buckets with the same
  # identities.  Exporting includes all buckets with matching
  # identities.  Standard glob matching rules apply.
  #

end                             # module Histamine

require('histamine/version')
require('histamine/command')
require('histamine/bucket')
require('histamine/history')
