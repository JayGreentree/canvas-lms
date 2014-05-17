#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# A custom DSL for writing metric calculators.
#
# Here's a full example showing how to define a context-free metric calculator,
# and a stateful one that requires a shared, pre-calculated variable:
#
#  module CanvasQuizStatistics::Analyzers
#    class MultipleChoice < Base
#      # A basic metric calculator. Your calculator block will be passed the
#      # set of responses, and needs to return the value of the metric.
#      #
#      # The key you specify will be written to the output, e.g:
#      # { "missing_answers": 1 }
#      metric :missing_answers do |responses|
#        responses.select { |r| r[:text].blank? }.length
#      end
#
#      # Let's say you need some pre-calculated variable for a bunch of metrics,
#      # call it "grades", we can prepare it in the special #build_context
#      # method and explicitly declare it as a dependency of each metric:
#      def build_context(responses)
#        ctx = {}
#        ctx[:grades] = responses.map { |r| r[:grade] }
#        ctx
#      end
#
#      # Notice how our metric definition now states that it requires the
#      # "grades" context variable to run, and it receives it as a block arg:
#      metric :graded_correctly => [ :grades ] do |responses, grades|
#        grades.select { |grade| grade == 'correct' }.length
#      end
#    end
#  end
module CanvasQuizStatistics::Analyzers::Base::DSL
  def metric(key, &calculator)
    deps = []

    if key.is_a?(Hash)
      deps, key = key.values.flatten, key.keys.first
    end

    self.metrics[question_type] << {
      key: key.to_sym,
      context: deps,
      calculator: calculator
    }
  end

  # You will need to do this if you're subclassing a concrete analyzer and would
  # like to inherit the metric calculators it defined, as the calculators are
  # scoped per question type and not the Ruby class.
  #
  # Example:
  #
  #   module CanvasQuizStatistics::Analyzers
  #     class TrueFalse < MultipleChoice
  #       inherit_metrics :multiple_choice_question
  #     end
  #   end
  #
  def inherit_metrics(question_type)
    self.metrics[self.question_type] += self.metrics[question_type].clone
  end

  def metrics
    @@metrics ||= Hash.new { |hsh, key| hsh[key] = [] }
  end
end