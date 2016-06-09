#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Node
  attr_reader :name, :lat, :lng

  def initialize( name, lat, lng )
    @name = name
    @lat  = lat
    @lng  = lng
  end
end


class CalcDistance
  # 定数 ( ベッセル楕円体 ( 旧日本測地系 ) )
  BESSEL_R_X  = 6377397.155000 # 赤道半径
  BESSEL_R_Y  = 6356079.000000 # 極半径

  # 定数 ( GRS80 ( 世界測地系 ) )
  GRS80_R_X   = 6378137.000000 # 赤道半径
  GRS80_R_Y   = 6356752.314140 # 極半径

  # 定数 ( WGS84 ( GPS ) )
  WGS84_R_X   = 6378137.000000 # 赤道半径
  WGS84_R_Y   = 6356752.314245 # 極半径

  # 定数 ( 測地系 )
  MODE = [ "BESSEL", "GRS-80", "WGS-84" ]

  def initialize( mode, lat1, lng1, lat2, lng2 )
    @mode = mode
    @lat1 = lat1
    @lng1 = lng1
    @lat2 = lat2
    @lng2 = lng2
  end

  def mode()
    MODE[@mode]
  end

  def dist()
    begin
      # 指定測地系の赤道半径・極半径を設定
      case @mode
        when 0
          r_x = BESSEL_R_X
          r_y = BESSEL_R_Y
        when 1
          r_x = GRS80_R_X
          r_y = GRS80_R_Y
        when 2
          r_x = WGS84_R_X
          r_y = WGS84_R_Y
      end

      # 2点の経度の差を計算（ラジアン）
      a_x = @lng1 * Math::PI / 180.0 - @lng2 * Math::PI / 180.0

      # 2点の緯度の差を計算（ラジアン）
      a_y = @lat1 * Math::PI / 180.0 - @lat2 * Math::PI / 180.0

      # 2点の緯度の平均を計算
      p = ( @lat1 * Math::PI / 180.0 + @lat2 * Math::PI / 180.0 ) / 2.0

      # 離心率を計算
      e = Math::sqrt( ( r_x ** 2 - r_y ** 2 ) / ( r_x ** 2 ).to_f )

      # 子午線・卯酉線曲率半径の分母Wを計算
      w = Math::sqrt( 1 - ( e ** 2 ) * ( ( Math::sin( p ) ) ** 2 ) )

      # 子午線曲率半径を計算
      m = r_x * ( 1 - e ** 2 ) / ( w ** 3 ).to_f

      # 卯酉線曲率半径を計算
      n = r_x / w.to_f

      # 距離を計算
      d  = ( a_y * m ) ** 2
      d += ( a_x * n * Math.cos( p ) ) ** 2
      d  = Math::sqrt( d )

      return d.round
    rescue => e
      # エラーメッセージ
      message = "[EXCEPTION][" + self.class.name + ".calc_dist] " + e.to_s
      STDERR.puts( message )
      exit 1
    end
  end
end

class Map
  attr_accessor :node
  attr_reader :min_cost
  attr_reader :min_route

  def initialize
    @node = Array.new
    @cost_matrix = Hash.new
    @min_cost = 0
    @min_route = nil
    alias :updatae_min_cost :update_min_cost0
  end

  def initNode
    @cost_matrix = Hash.new
    @min_cost = 0
    @min_route = nil

    alias :update_min_cost :update_min_cost0

    @node << Node.new("NS", 36.054591, 136.245859)
    @node << Node.new("パリオ", 36.062168, 136.240826)
    @node << Node.new("福井駅", 36.062132, 136.223227)
    @node << Node.new("片町",   36.065525, 136.215073)
    @node << Node.new("越前大野駅", 35.983176, 136.496954)
    @node << Node.new("勝山駅", 36.056291, 136.492088)
    @node << Node.new("鯖江駅", 35.943451, 136.188843)
    @node << Node.new("武生駅", 35.903455, 136.170902)
    @node << Node.new("東尋坊", 36.237653, 136.125425)
    @node << Node.new("あわら温泉", 36.222975, 136.193638)
    @node << Node.new("永平寺", 36.055608, 136.355256)
  end

  def get_cost( n1, n2 )
    if @cost_matrix[ [n1, n2] ] == nil
      # 出発地と目的地の緯度経度を指定して距離を算出
      calc = CalcDistance.new( 2, @node[n1].lat.to_f, @node[n1].lng.to_f, @node[n2].lat.to_f, @node[n2].lng.to_f )
      @cost_matrix[ [n1, n2] ] = calc.dist.to_i
    end

    @cost_matrix[ [n1, n2] ]
  end

  def update_min_cost0( cost, route )
    @min_cost = cost
    @min_route = route
    alias :update_min_cost :update_min_cost1
  end

  def update_min_cost1( cost, route )
    if cost < @min_cost
      @min_cost = cost
      @min_route = route
    end
  end
end


map = Map.new
map.initNode

puts "総当り"
t_start = Time.now.instance_eval { self.to_i * 1000 + (usec/1000) }
(1...map.node.length).to_a.permutation(map.node.length - 1) do |route|
  route.insert 0, 0
  route.push 0

  cost = 0
  for n in 0...(route.size - 1) do
    cost += map.get_cost( route[n], route[n + 1] )
  end

  map.update_min_cost( cost, route )  
end
t_end = Time.now.instance_eval { self.to_i * 1000 + (usec/1000) }

for n in 0...map.min_route.size do
  print "#{map.node[ map.min_route[n] ].name}"
  print " -> " unless n == ( map.min_route.size - 1 )
end
puts ""
t_interval = t_end - t_start

puts "経過時間 #{(t_interval / 1000).round.to_s} 秒 #{( t_interval - ( t_interval / 1000 ).round * 1000 ).to_s} ミリ秒"
