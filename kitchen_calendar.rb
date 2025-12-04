#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a PDF with a large calendar for the given or current year.
# Usage: `./kitchen_calendar.rb [year]`

require 'bundler/setup'
require 'date'
require 'prawn'
require 'prawn/measurement_extensions'
require_relative 'holidays'

class KitchenCalendar
  include Prawn::View

  COLOR = '2a3773'
  WHITE = 'FFFFFF'
  LINE_WIDTH = 1.5

  MONTH_NAMES = %w[
    null
    Januar
    Februar
    März
    April
    Mai
    Juni
    Juli
    August
    September
    Oktober
    November
    Dezember
  ].freeze

  WEEKDAY_NAMES = %w[So Mo Di Mi Do Fr Sa].freeze

  attr_reader :year

  def initialize(year)
    @year = year
  end

  def generate_pdf
    render
    save_as(filename)
  end

  def filename = "calendar-#{year}.pdf"

  private

  def document
    @document ||= Prawn::Document.new(page_size:, margin:)
  end

  def render
    setup
    (1..12).each do |month|
      render_month(month)
    end
  end

  def setup
    font(font_name, style: font_style)
    stroke_color(COLOR)
    fill_color(COLOR)
    line_width(LINE_WIDTH)
  end

  def render_month(month)
    start_new_page if month > 1
    render_title(month)
    render_dates(month_dates(month))
  end

  def render_title(month)
    text_box(MONTH_NAMES.fetch(month), at: [0, title_top], size: font_size_title)
  end

  def month_dates(month)
    (Date.new(year, month, 1)..Date.new(year, month, -1)).to_a
  end

  def render_dates(dates)
    render_vertical_line(0)
    dates.each do |date|
      render_date(date)
    end
  end

  def render_date(date)
    column_left = date_offset(date) * column_width
    text_left = column_left + padding_text

    render_vertical_line(column_left + column_width)
    render_weekend_background(date, column_left)
    render_weekday_label(date, text_left)
    render_date_label(date, text_left)
    render_holiday_name(date, text_left)
    render_znacht(text_left)
  end

  def date_offset(date)
    date.day - 1
  end

  def render_vertical_line(x)
    stroke_vertical_line(column_height, 0, at: x)
  end

  def render_weekend_background(date, column_left)
    return unless [0, 6].include?(date.wday)

    fill_rectangle([column_left + padding_box, column_height],
                   weekend_bg_width,
                   weekend_bg_height)
    fill_color(WHITE) # for weekday label
  end

  def render_weekday_label(date, text_left)
    text_box(WEEKDAY_NAMES.fetch(date.wday),
             at: [text_left, weekday_top],
             size: font_size_wday)
  end

  def render_date_label(date, text_left)
    fill_color(COLOR) # change back
    text_box("#{date.day}.#{date.month}.",
             at: [text_left, date_top],
             size: font_size_date)
  end

  def render_holiday_name(date, text_left)
    return unless holidays.key?(date)

    text_box(holidays[date],
             at: [text_left, holiday_top],
             size: font_size_holiday,
             width: holiday_width)
  end

  def render_znacht(text_left)
    text_box('Z:',
             at: [text_left, z_top],
             size: font_size_content)
  end

  def holidays
    @holidays ||= Holidays.new.dates(year)
  end

  def font_name = Dir.glob('./*.ttf').first || 'Helvetica'
  def font_style = :bold
  def font_size_title = 40
  def font_size_wday = 20
  def font_size_date = 18
  def font_size_content = 12
  def font_size_holiday = 9
  def leading = 4
  def page_size = [900.mm, 162.mm].freeze
  def margin = 12.mm
  def column_width = 28.mm
  def column_height = 105.mm
  def padding_text = 4.mm
  def padding_box = 3.mm
  def title_top = column_height + 28.mm
  def weekend_bg_width = column_width - padding_box
  def weekend_bg_height = font_size_wday + leading
  def weekday_top = column_height - leading
  def date_top = weekday_top - leading - font_size_wday
  def holiday_top = date_top - leading - font_size_date
  def holiday_width = column_width - padding_text
  def z_top = 20.mm
end

class KitchenCalendarA3 < KitchenCalendar
  MIDDLE_OF_MONTH = 16

  def filename = "calendar-#{year}-a3.pdf"

  private

  def page_size = [420.mm, 297.mm].freeze
  def margin = 5.mm
  def font_size_holiday = 8.5
  def column_width = 25.6.mm
  def column_height = 98.mm
  def padding_text = 3.mm
  def padding_box = 2.mm
  def middle = page_size[1] / 2.0 - margin
  def bounds_width = page_size[0] - 2 * margin
  def bounds_height = column_height + 7.mm
  def title_top = middle + margin + bounds_height + 24.mm

  def render_dates(dates)
    render_half_month(middle + margin) do
      super(dates[0...MIDDLE_OF_MONTH])
    end
    render_half_month(0) do
      super(dates[MIDDLE_OF_MONTH..])
    end
    render_cut_marker
  end

  def render_half_month(offset, &)
    bounding_box([0, offset + bounds_height], width: bounds_width, height: column_height, &)
  end

  def render_cut_marker
    mask(:line_width) do
      line_width(0.5)
      stroke_horizontal_line(0, 5.mm, at: middle)
      stroke_horizontal_line(bounds_width - 5.mm, bounds_width, at: middle)
    end
  end

  def date_offset(date)
    if date.day > MIDDLE_OF_MONTH
      super - MIDDLE_OF_MONTH
    else
      super
    end
  end
end

year = (ARGV.last || Date.today.year).to_i
a3 = ARGV.first == '--a3'

calendar = a3 ? KitchenCalendarA3.new(year) : KitchenCalendar.new(year)
calendar.generate_pdf
`open #{calendar.filename} &`
