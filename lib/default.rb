require 'nanoc'

module Nanoc::Filters
  class Wikilink < ::Nanoc::Filter
    include ::Nanoc::Helpers::HTMLEscape

    def run(content, params = {})
      content = content.gsub(/(?<!\[\[)(([A-Z][a-z0-9]+){2,})(?!\]\])/) do |match|
        inner = $1.strip
        linking inner
      end

      content.gsub(/\[\[(.*?[^:])\]\]/) do |match|
        inner = $1.strip
        linking inner
      end
    end
    
    def linking(inner)
      title, link = inner.split('|', 2)
      if link.nil?
        link = title
        title = nil
      end

      puts "searching for #{link} in #{item.path} ..."
      target = find_item(link)
      if target
        title = html_escape((title || target[:title] || link).strip)
        %Q[<a href="#{target.path}">#{title}</a>]
      else
        title = html_escape((title || link).strip)
        %Q[#{link_to(title, link, :class => 'missing')}]
      end
    end

    def find_item(identifiers)
      items.find do |item| 
        item_identifier = item.identifier.without_ext[1..-1] # /foo.txt => foo
        identifiers.include?(item_identifier) 
      end
    end
  end
end

class Nanoc::Identifier
  def link_title
    self.without_ext[1..-1]
  end
end

require 'nokogiri'

class NokogiriTOC
  def self.level_text
    [@level["h2"], @level["h3"], @level["h4"]].join(".").gsub(/\.0/, "")
  end
  
  def self.run(html, options = {})
    options[:content_selector] ||= "body"

    doc = Nokogiri::HTML(html)
    toc_data = []
    
    @level = {"h2" => 0, "h3" => 0, "h4" => 0}
    selector = @level.keys.map{|h| Nokogiri::CSS.xpath_for("#{options[:content_selector]} #{h}")}.join("|")

    current_heading = nil
    
    doc.xpath(selector).each do |node|
      current_heading = node.name
      @level[node.name] += 1

      @level["h3"] = 0 if node.name == "h2"
      @level["h4"] = 0 if node.name == "h2" || node.name == "h3"

      data = {:title => node.content, :link => '#' + node['id'], :children => []}
      
      parent = case node.name
                 when "h2" then toc_data
                 when "h3" then toc_data.last[:children]
                 when "h4" then toc_data.last[:children].last[:children]
               end
      parent << data
    end

    toc = doc.create_element("ol")
    build_toc(toc, toc_data)

    toc.to_html
  end

  def self.build_toc(toc, data)
    data.each do |item|
      li = toc.document.create_element("li")
      li.add_child(li.document.create_element("a", item[:title], :href => item[:link]))
      unless item[:children].empty?
        build_toc(li.add_child(li.document.create_element("ol")), item[:children])
      end
      toc.add_child(li)
    end
    toc
  end
end

module NanocSite
  class AddTOCFilter < Nanoc::Filter

    identifier :add_toc

    def run(content, params={})
      content.gsub('{{TOC}}') do
        toc = NokogiriTOC.run(content)
        
        res = '<details class="toc" open="open">'
        res << '<summary>Table of Contents</summary>'
        res << toc
        res << '</details>'
        
        res
      end
    end    
  end
end

module Nanoc::Filters
  autoload 'Wikilink', 'nanoc/filters/wikilink'
  autoload 'TOC', 'nanoc/filters/toc'

  Nanoc::Filter.register '::Nanoc::Filters::Wikilink', :wikilink
  Nanoc::Filter.register '::Nanoc::Filters::TOC', :toc
end
