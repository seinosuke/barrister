module Barrister::AStar
  class Node

    attr_accessor :block, :current, :from, :move_cost

    def initialize(x, y)
      @current = [x, y]
      @from = []
      @block = false

      @move_cost = 0.0
      @heuristic_cost = Math.sqrt(
        (Algorithm.goal[0] - @current[0]) ** 2 +
        (Algorithm.goal[1] - @current[1]) ** 2
      )
    end

    def score
      @move_cost + @heuristic_cost
    end
  end
end
