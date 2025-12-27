# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ============================================================================
# Printer Profiles - Reference Data
# ============================================================================
# Load printer profiles from JSON for users to select from when creating printers

puts "🖨️  Seeding printer profiles..."

json_path = Rails.root.join("public/printer_profiles_v2.json")
if File.exist?(json_path)
  profiles = JSON.parse(File.read(json_path))
  created_count = 0
  profiles.each do |p|
    PrinterProfile.find_or_create_by!(manufacturer: p["manufacturer"], model: p["model"]) do |pp|
      pp.category = p["category"]
      pp.technology = p["technology"]
      pp.power_consumption_peak_watts = p["power_consumption_peak_watts"]
      pp.power_consumption_avg_watts = p["power_consumption_avg_watts"]
      pp.cost_usd = p["cost_usd"]
      pp.source = p["source"]
      created_count += 1
    end
  end
  puts "  ✅ Loaded #{PrinterProfile.count} printer profiles (#{created_count} new)"
else
  puts "  ⚠️  No printer_profiles_v2.json found, skipping"
end

# ============================================================================
# Blog Articles - Example Content
# ============================================================================
#
# NOTE: These are example articles for development and testing.
# In production, create articles via RailsAdmin at /admin/article/new
# Then translate using: bin/translate-articles
#
# To load these seeds: bin/rails db:seed
# To reset: bin/rails db:reset (WARNING: Destroys all data!)

puts "🌱 Seeding blog articles..."

# Example Article 1: Complete Guide to 3D Printing Costs
article1 = Article.find_or_initialize_by(slug_en: "complete-guide-3d-printing-costs-2025")
article1.assign_attributes(
  author: "CalcuMake Team",
  published_at: 2.days.ago,
  featured: true
)

I18n.with_locale(:en) do
  article1.title = "The Complete Guide to 3D Printing Costs in 2025"
  article1.slug = "complete-guide-3d-printing-costs-2025"
  article1.excerpt = "Master the art of calculating 3D printing costs. Learn about filament, electricity, labor, and hidden expenses that impact your bottom line."
  article1.meta_description = "Complete guide to 3D printing costs in 2025. Calculate filament, electricity, labor, and machine costs accurately for your business."
  article1.meta_keywords = "3d printing costs, filament cost, printing calculator, business pricing"
  article1.content = <<~HTML
    <h2>Understanding 3D Printing Costs</h2>
    <p>Running a profitable 3D printing business requires accurate cost calculation. Whether you're a hobbyist or professional, understanding your true costs is essential for sustainable operations.</p>

    <h2>Major Cost Categories</h2>

    <h3>1. Filament Costs</h3>
    <p>Filament typically represents 40-60% of your printing costs. Calculate it accurately by:</p>
    <ul>
      <li>Measuring actual weight used (not estimated)</li>
      <li>Including waste and purging</li>
      <li>Factoring in failed prints</li>
      <li>Tracking bulk purchase discounts</li>
    </ul>

    <h3>2. Electricity Costs</h3>
    <p>Often overlooked, electricity can add 5-15% to your costs. Consider:</p>
    <ul>
      <li>Printer power consumption (typically 50-250W)</li>
      <li>Heated bed power draw</li>
      <li>Local electricity rates</li>
      <li>Cooling and ventilation</li>
    </ul>

    <h3>3. Labor Costs</h3>
    <p>Your time is valuable. Include time for:</p>
    <ul>
      <li>Print preparation and slicing</li>
      <li>Print monitoring</li>
      <li>Post-processing</li>
      <li>Quality control</li>
    </ul>

    <h2>Using the CalcuMake Calculator</h2>
    <p>Our free <a href="/3d-print-pricing-calculator">3D Print Pricing Calculator</a> helps you calculate costs accurately across multiple plates and filaments.</p>

    <h2>Hidden Costs to Consider</h2>
    <p>Don't forget these often-missed expenses:</p>
    <ul>
      <li>Printer maintenance and wear</li>
      <li>Failed prints and waste</li>
      <li>Storage and organization</li>
      <li>Software licenses</li>
    </ul>

    <h2>Conclusion</h2>
    <p>Accurate cost tracking is the foundation of a profitable 3D printing business. Use our calculator to ensure you're pricing competitively while maintaining healthy margins.</p>
  HTML
  article1.translation_notice = false
end

article1.save!
puts "  ✅ Created: '#{article1.title_en}'"

# Example Article 2: Multi-Plate Printing Efficiency
article2 = Article.find_or_initialize_by(slug_en: "multi-plate-3d-printing-efficiency")
article2.assign_attributes(
  author: "CalcuMake Team",
  published_at: 5.days.ago,
  featured: false
)

I18n.with_locale(:en) do
  article2.title = "Multi-Plate 3D Printing: Maximizing Printer Efficiency"
  article2.slug = "multi-plate-3d-printing-efficiency"
  article2.excerpt = "Learn how to maximize your 3D printer efficiency with multi-plate printing strategies. Reduce costs and increase throughput."
  article2.meta_description = "Maximize 3D printer efficiency with multi-plate printing. Learn strategies to reduce costs and increase throughput for your print business."
  article2.meta_keywords = "multi-plate printing, 3d printer efficiency, batch printing, print optimization"
  article2.content = <<~HTML
    <h2>What is Multi-Plate Printing?</h2>
    <p>Multi-plate printing involves printing multiple build plates in sequence or simultaneously, maximizing your printer's uptime and efficiency.</p>

    <h2>Benefits of Multi-Plate Workflows</h2>
    <ul>
      <li><strong>Reduced setup time</strong> - Prepare multiple plates at once</li>
      <li><strong>Better material usage</strong> - Optimize filament consumption</li>
      <li><strong>Increased throughput</strong> - Print more parts per day</li>
      <li><strong>Lower per-unit costs</strong> - Amortize fixed costs across more units</li>
    </ul>

    <h2>Calculating Multi-Plate Costs</h2>
    <p>The <a href="/3d-print-pricing-calculator">CalcuMake Calculator</a> supports up to 10 plates with different filaments per plate. Track costs accurately across your entire job.</p>

    <h2>Best Practices</h2>
    <ol>
      <li>Group similar parts by material and layer height</li>
      <li>Optimize plate layouts for maximum density</li>
      <li>Consider print time vs. material usage tradeoffs</li>
      <li>Track each plate's costs separately for accurate pricing</li>
    </ol>

    <h2>Common Pitfalls to Avoid</h2>
    <ul>
      <li>Mixing incompatible materials on the same plate</li>
      <li>Overloading plates and risking failures</li>
      <li>Forgetting to account for setup time</li>
      <li>Not tracking individual plate performance</li>
    </ul>
  HTML
  article2.translation_notice = false
end

article2.save!
puts "  ✅ Created: '#{article2.title_en}'"

# Example Article 3: Business Pricing Strategies
article3 = Article.find_or_initialize_by(slug_en: "3d-printing-business-pricing-strategies")
article3.assign_attributes(
  author: "CalcuMake Team",
  published_at: 1.week.ago,
  featured: true
)

I18n.with_locale(:en) do
  article3.title = "3D Printing Business Pricing: How to Set Profitable Rates"
  article3.slug = "3d-printing-business-pricing-strategies"
  article3.excerpt = "Set profitable prices for your 3D printing business. Learn markup strategies, competitive analysis, and value-based pricing."
  article3.meta_description = "Learn how to price 3D printing services profitably. Strategies for markup, competitive analysis, and value-based pricing."
  article3.meta_keywords = "3d printing pricing, business strategy, markup, profit margins"
  article3.content = <<~HTML
    <h2>Pricing Fundamentals</h2>
    <p>Successful 3D printing businesses balance competitive pricing with healthy profit margins. This guide shows you how.</p>

    <h2>Three Pricing Strategies</h2>

    <h3>1. Cost-Plus Pricing</h3>
    <p>Calculate total costs and add a markup:</p>
    <ul>
      <li>Materials + Labor + Overhead = Base Cost</li>
      <li>Base Cost × Markup % = Selling Price</li>
      <li>Typical markup: 30-100% depending on market</li>
    </ul>

    <h3>2. Competitive Pricing</h3>
    <p>Match or beat competitor prices:</p>
    <ul>
      <li>Research local and online competitors</li>
      <li>Identify your unique value propositions</li>
      <li>Price slightly below for commodity items</li>
      <li>Price at premium for specialized services</li>
    </ul>

    <h3>3. Value-Based Pricing</h3>
    <p>Price based on customer value received:</p>
    <ul>
      <li>Custom parts command higher prices</li>
      <li>Rush orders warrant premium rates</li>
      <li>Technical consulting adds value</li>
      <li>Design services increase pricing power</li>
    </ul>

    <h2>Using CalcuMake for Pricing</h2>
    <p>Our <a href="/3d-print-pricing-calculator">pricing calculator</a> helps you:</p>
    <ul>
      <li>Calculate accurate base costs</li>
      <li>Track profit margins per job</li>
      <li>Analyze pricing trends over time</li>
      <li>Generate professional quotes</li>
    </ul>

    <h2>Profit Margin Targets</h2>
    <ul>
      <li><strong>Commodity prints:</strong> 30-50% margin</li>
      <li><strong>Custom orders:</strong> 50-100% margin</li>
      <li><strong>Design services:</strong> 100-200% margin</li>
      <li><strong>Rush orders:</strong> Add 50-100% premium</li>
    </ul>
  HTML
  article3.translation_notice = false
end

article3.save!
puts "  ✅ Created: '#{article3.title_en}'"

puts "🎉 Seeded #{Article.count} blog articles!"
puts ""
puts "Next steps:"
puts "  1. Translate articles: bin/translate-articles"
puts "  2. Publish articles: Set published_at in RailsAdmin"
puts "  3. View blog: Visit /blog"
puts ""
