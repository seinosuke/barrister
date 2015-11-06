module Barrister::AStar
  class Algorithm

    # This method is used in Node class to calculate the heuristic cost.
    def self.goal=(ary)
      @goal = ary
    end

    def self.goal
      @goal
    end

    # def initialize(x_size, y_size, start, goal)
    def initialize(options = {})
      options.each { |key ,val| eval "@#{key} = #{val}" }
      self.class.goal = @goal

      reset_nodes
      set_blocks(@blocks)
    end

    # Reset nodes, open nodes and closed nodes to default state.
    def reset_nodes
      @shortest_route = []
      @nodes = Array.new(@x_size).map{ Array.new(@y_size, nil) }
      @open_nodes = Array.new(@x_size).map{ Array.new(@y_size, nil) }
      @closed_nodes = Array.new(@x_size).map{ Array.new(@y_size, nil) }

      @x_size.times do |x|
        @y_size.times do |y|
          @nodes[x][y] = Node.new(x, y)
        end
      end
    end

    def set_blocks(blocks)
      blocks.each do |xy|
        @nodes[xy[0]][xy[1]].block = true
      end
    end

    # Start searching by using the A* algorithm.
    def start
      @open_nodes[@start[0]][@start[1]] = Node.new(@start[0], @start[1])
      @open_nodes[@start[0]][@start[1]].from = [0, 0]

      loop do
        # Search a position of the node that has the minimun score from the open nodes.
        target_pos = 
          @open_nodes.flatten.select { |node| !node.nil? }
          .min_by { |node| node.score }.current
        open_node(target_pos[0], target_pos[1])
        break if target_pos == @goal
      end

      # Get the shortest route from the closed list.
      node = @closed_nodes[@goal[0]][@goal[1]]
      loop do
        break if [node.from[0], node.from[1]] == @start
        @shortest_route << node.from
        node = @closed_nodes[node.from[0]][node.from[1]]
      end

    rescue Interrupt
      exit 1
    end

    # Open a node at (x, y).
    def open_node(x, y)
      [*-1..1].repeated_permutation(2).to_a
      .reject { |dxdy| dxdy == [0, 0] }#.each do |dx, dy|
      .reject { |dx, dy| dx*dy != 0 }.each do |dx, dy| # prohibit a move in the oblique direction

        next if ( x+dx == -1 || x+dx == @x_size || y+dy == -1 || y+dy == @y_size )
        next if @nodes[x+dx][y+dy].block

        @nodes[x+dx][y+dy].move_cost = @open_nodes[x][y].move_cost + 1
        @nodes[x+dx][y+dy].from = [x, y]
        check_unique(x+dx, y+dy)
      end

      # Move the node at (x, y) from the open list to the closed list.
      @closed_nodes[x][y] = Marshal.load(Marshal.dump(@open_nodes[x][y]))
      @open_nodes[x][y] = nil
    end

    # Check whether or not the node at (x, y) is a new node.
    def check_unique(x, y)

      # If a node at (x, y) exists in the open list, 
      # and a score of the new node is lower than the its score,
      # add the new node to the open list.
      if @open_nodes[x][y]
        if @open_nodes[x][y].score > @nodes[x][y].score
          @open_nodes[x][y].move_cost = @nodes[x][y].move_cost
          @open_nodes[x][y].from = Marshal.load(Marshal.dump(@nodes[x][y].from))
        end
        return
      end

      # If a node at (x, y) exists in the closed list, 
      # and a score of the new node is lower than the its score,
      # add the new node to the open list and remove from the closed list.
      if @closed_nodes[x][y]
        if @closed_nodes[x][y].score > @nodes[x][y].score
          @closed_nodes[x][y] = nil
          @open_nodes[x][y] = Node.new(x, y)

          @open_nodes[x][y].move_cost = @nodes[x][y].move_cost
          @open_nodes[x][y].from = Marshal.load(Marshal.dump(@nodes[x][y].from))
        end
        return
      end

      # If a node at (x, y) exists in the open list and closed list,
      # add to the open list.
      @open_nodes[x][y] = Node.new(x, y)
      @open_nodes[x][y].move_cost = @nodes[x][y].move_cost
      @open_nodes[x][y].from = Marshal.load(Marshal.dump(@nodes[x][y].from))
    end

    # Return the shortest route array.
    def route
      @shortest_route.unshift @goal
    end
  end
end
