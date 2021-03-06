#!/bin/env ruby
# encoding: utf-8

require_relative 'config/config'
require_relative '../lib/physics'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
MAX_ANGLE = 100.0
MIN_ANGLE = 5.0

class Numeric
  def radians_to_vec2
    CP::Vec2.new(Math::cos(self), Math::sin(self))
  end

  def angle_to_vec2
    CP::Vec2.new(Math::cos(self * Math::PI / 180.0), - Math::sin(self * Math::PI / 180.0))
  end
end

module ZOrder
  Background, Ball, Foreground, UI = *0..3
end

class Ball < PhysicObject
  attr_reader :initial_velocity
  
  def setup    
    reset_position
  end

  def reset_position
    @initial_velocity = CP::Vec2.new(0.0, 50 + rand(80))
    @shape.body.v = @initial_velocity
    @shape.body.p = CP::Vec2.new(140, 100)
    @waiting_success = true
  end

  def validate_position
    if (@shape.body.p.x > SCREEN_WIDTH || @shape.body.p.x < 0 || 
        @shape.body.p.y > SCREEN_HEIGHT || @shape.body.v.y.abs < 0.0001)

      reset_position
      return true
    end

    return false
  end

  def success
    if (@waiting_success && @shape.body.p.x > 700 && @shape.body.p.y > 300)
      @waiting_success = false
      return true
    end
    return false
  end

end

class GameWindow < PhysicWindow

  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, false, 16)
    self.caption = "Physics Simulation #5 - Valley ball"

    @background_image = Gosu::Image["fundo-demo-5.png"]
    @foreground_image = Gosu::Image["fundo-demo-5-frente.png"]
    @point_sound= Gosu::Sample["Beep.wav"]
    @info_area = Chingu::Text.create("", :x => 300, :y => 10, :color => Gosu::Color::RED)    

    @score = 0    
    @segment_shapes = []
    segment_points = []
    @simulation_speed = 0.08
    @total = 0
      
    $space.damping = 1.0
    $space.gravity = CP::Vec2.new(0.0, 15.0)
    @substeps = 1
    @initial_dt = 1.0 / 60.0

    segment_points << CP::Vec2.new(100.0, 275.0)
    segment_points << CP::Vec2.new(310.0, 455.0)
    segment_points << CP::Vec2.new(365.0, 475.0)
    segment_points << CP::Vec2.new(390.0, 480.0)
    segment_points << CP::Vec2.new(445.0, 470.0)
    segment_points << CP::Vec2.new(510.0, 435.0)
    segment_points << CP::Vec2.new(642.0, 330.0)
    segment_points << CP::Vec2.new(700.0, 300.0)
    segment_points << CP::Vec2.new(750.0, 295.0)
    segment_points << CP::Vec2.new(800.0, 310.0)

    for i in 0..segment_points.size-2
      next if i == 7 # hole

      segmentBody = CP::StaticBody.new()
      segmentShape = CP::Shape::Segment.new(segmentBody, segment_points[i], segment_points[i+1], 0.1)
      segmentShape.e = 0.0
      segmentShape.u = 0.8
      @segment_shapes << segmentShape
      $space.add_shape(segmentShape)      
    end

    @ball = Ball.create(ObjectConfig::Ball)
  end

  def info
    "INFO
    Success: #{@score}/#{@total}
    Speed (x, y): (#{'%.3f' % @ball.shape.body.v.x}, #{'%.3f' % @ball.shape.body.v.y})
    Initial Vy: #{@ball.initial_velocity.y.to_s}
    Speed of Simulation: #{'%.2f' % (@simulation_speed * 100 + 1)}
    Space] : Restart
    [D] : Show lines
    #{@feedbackMessage}"
  end

  def update
    @dt = @initial_dt + @simulation_speed

    @substeps.times do
      super

      @ball.shape.body.reset_forces      
      
      if @ball.validate_position
        @feedbackMessage = ""
        @total += 1
      end
            
      if @ball.success
        @feedbackMessage = "Success! (Vy = " + @ball.initial_velocity.y.to_s + ")"
        @point_sound.play         
        @score += 1
        @total += 1
        @ball.reset_position
      end

      if button_down? Gosu::KbUp
        @simulation_speed += 0.01 if @simulation_speed < 0.1
      end
      if button_down? Gosu::KbDown
        @simulation_speed -= 0.01 if @simulation_speed > 0.0
      end
      
      if button_down? Gosu::KbSpace
         @ball.reset_position
      end

    end    
  end

  def draw
    super

    if $draw_segments 
      @segment_shapes.each { |segment| 
        vectorA = segment.a
        vectorB = segment.b
        $window.draw_line(vectorA.x, vectorA.y, Gosu::Color::BLUE, vectorB.x, vectorB.y, Gosu::Color::BLUE)
      } 
    else 
      @foreground_image.draw(0, 0, ZOrder::Foreground)
      @background_image.draw(0, 0, ZOrder::Background)
      @ball.draw
    end 

  end

end

window = GameWindow.new
window.show
